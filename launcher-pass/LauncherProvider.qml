import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services.UI

Item {
  id: root

  property var pluginApi: null
  property var launcher: null
  property string name: "Launcher pass"
  property string supportedLayouts: "list"
  property bool handleSearch: true
  property bool supportsAutoPaste: false

  property var cachedEntries: []
  property bool loaded: false
  property string currentPath: ""
  property var entryStack: ([])
  property string searchQuery: ""

  property bool isDetailMode: false
  property var selectedEntry: null
  property var selectedField: null

  readonly property string passwordStoreDir: {
    var configured = pluginApi?.pluginSettings?.storePath || pluginApi?.manifest?.metadata?.defaultSettings?.storePath || ""
    if (configured !== "") return configured
    var envHome = Quickshell.env("HOME") || ""
    return envHome + "/.password-store"
  }

  Process {
    id: listProc
    stdout: StdioCollector {}
    onExited: function(exitCode, exitStatus) {
      if (exitCode === 0) {
        parseEntries(listProc.stdout.text, false)
      }
      loaded = true
      if (launcher) launcher.updateResults()
    }
  }

  Process {
    id: searchAllProc
    stdout: StdioCollector {}
    onExited: function(exitCode, exitStatus) {
      if (exitCode === 0) {
        parseEntries(searchAllProc.stdout.text, true)
      }
      loaded = true
      if (launcher) launcher.updateResults()
    }
  }

  Process {
    id: showProc
    stdout: StdioCollector {}
    onExited: function(exitCode, exitStatus) {
      if (exitCode === 0) {
        var data = parsePassEntry(showProc.stdout.text)
        root.selectedEntry = { "path": showProcPath, "data": data }
        root.isDetailMode = true
        root.selectedField = null
        if (launcher) {
          launcher.setSearchText(">pass ")
          launcher.updateResults()
        }
      }
    }
  }

  property string showProcPath: ""

  Process {
    id: copyProc
    onExited: function(exitCode, exitStatus) {
      ToastService.showNotice(pluginApi?.tr("notification.copied") || "Copied to clipboard")
    }
  }

  function listCurrentDir() {
    var targetPath = currentPath === "" ? passwordStoreDir : passwordStoreDir + "/" + currentPath
    var escapedPath = targetPath.replace(/'/g, "'\\''")
    listProc.exec(["find", escapedPath, "-maxdepth", "1", "-type", "f", "-name", "*.gpg", "-printf", "%f\n", "-o", "-maxdepth", "1", "-type", "d", "-not", "-name", ".*", "-printf", "%f/\n"])
  }

  function searchAllPasswords() {
    var escapedStore = passwordStoreDir.replace(/'/g, "'\\''")
    searchAllProc.exec(["find", escapedStore, "-type", "f", "-name", "*.gpg", "-printf", "%P\n"])
  }

  function parseEntries(text, isSearch) {
    var lines = text.split('\n').filter(function(l) { return l.trim() !== "" })
    var entries = []
    var seenDirs = {}

    for (var i = 0; i < lines.length; i++) {
      var line = lines[i].trim()
      if (line === "") continue

      var isDir = line.endsWith('/')
      var name = isDir ? line.slice(0, -1) : line

      if (!isDir && name.endsWith('.gpg')) {
        name = name.slice(0, -4)
      }

      var fullPath = currentPath === "" ? name : currentPath + "/" + name

      if (isSearch) {
        var lastSlash = name.lastIndexOf('/')
        if (lastSlash !== -1) {
          var dirPath = name.substring(0, lastSlash)
          if (!seenDirs[dirPath]) {
            seenDirs[dirPath] = true
            entries.push({
              "name": dirPath,
              "fullPath": dirPath,
              "isDir": true,
              "isPassword": false
            })
          }
        }
      }

      entries.push({
        "name": name,
        "fullPath": isSearch ? name : fullPath,
        "isDir": isDir,
        "isPassword": !isDir
      })
    }

    entries.sort(function(a, b) {
      if (a.isDir !== b.isDir) return a.isDir ? -1 : 1
      return a.name.localeCompare(b.name)
    })

    cachedEntries = entries
  }

  function init() {
    loaded = false
    if (searchQuery !== "") {
      searchAllPasswords()
    } else {
      listCurrentDir()
    }
  }

  function onOpened() {
    currentPath = ""
    entryStack = []
    searchQuery = ""
    cachedEntries = []
    loaded = false
    isDetailMode = false
    selectedEntry = null
    selectedField = null
    init()
  }

  function handleCommand(searchText) {
    return searchText.startsWith(">pass")
  }

  function commands() {
    return [{
      "name": ">pass",
      "description": "Search gnu pass password entries",
      "icon": "lock",
      "isTablerIcon": true,
      "onActivate": function() {
        launcher.setSearchText(">pass ")
      }
    }]
  }

  function goBack() {
    if (entryStack.length > 0) {
      var prev = entryStack.pop()
      currentPath = prev.path
      searchQuery = prev.query
      init()
    }
  }

  function navigateToPath(path) {
    entryStack.push({
      "path": currentPath,
      "query": searchQuery
    })
    currentPath = path
    searchQuery = ""
    isDetailMode = false
    selectedEntry = null
    init()
  }

  function parsePassEntry(output) {
    var lines = output.split('\n')
    var data = {
      "password": "",
      "fields": []
    }

    var passwordLine = true
    for (var i = 0; i < lines.length; i++) {
      var line = lines[i].trim()
      if (line === "") continue

      if (passwordLine && i === 0) {
        data.password = line
        passwordLine = false
        continue
      }

      var colonIndex = line.indexOf(': ')
      if (colonIndex > 0) {
        var key = line.substring(0, colonIndex)
        var value = line.substring(colonIndex + 2)
        data.fields.push({"key": key, "value": value})
      }
    }
    return data
  }

  function fuzzyMatch(query, target) {
    query = query.toLowerCase()
    target = target.toLowerCase()

    if (query.length === 0) {
      return 1
    }

    var queryParts = query.split(/\s+/).filter(function(p) { return p.length > 0 })
    if (queryParts.length === 0) {
      return 1
    }

    var targetIndex = 0
    var lastMatchIndex = -1
    var lastPartEnd = -1

    for (var p = 0; p < queryParts.length; p++) {
      var part = queryParts[p]
      var partMatched = false

      for (var i = targetIndex; i < target.length; i++) {
        if (target[i] === part[0]) {
          var match = true
          for (var j = 1; j < part.length; j++) {
            if (i + j >= target.length || target[i + j] !== part[j]) {
              match = false
              break
            }
          }
          if (match) {
            if (p === 0 && i === 0) {
              lastMatchIndex = i
            } else if (i > lastPartEnd + 1) {
              lastMatchIndex = i
            }
            lastPartEnd = i + part.length - 1
            targetIndex = i + part.length
            partMatched = true
            break
          }
        }
      }

      if (!partMatched) {
        return 0
      }
    }

    var score = 0

    if (target.startsWith(queryParts[0])) {
      score += 50
    } else if (target.indexOf(query) !== -1) {
      score += 25
    }

    if (lastMatchIndex === 0) {
      score += 15
    } else if (lastMatchIndex > 0 && target[lastMatchIndex - 1] === '/') {
      score += 12
    } else if (lastMatchIndex > 0) {
      score += 5
    }

    score += Math.max(0, 20 - (target.length - query.replace(/\s+/g, '').length) / 2)

    return score
  }

  function getResults(searchText) {
    if (!searchText.startsWith(">pass")) {
      return []
    }

    if (root.isDetailMode && root.selectedEntry) {
      return getPasswordFieldResults()
    }

    var newQuery = searchText.slice(5).trim()
    if (newQuery !== searchQuery) {
      searchQuery = newQuery
      if (!root.isDetailMode) {
        selectedEntry = null
        init()
      }
    }

    if (!loaded) {
      return [{
        "name": "Loading...",
        "description": "Loading password entries...",
        "icon": "refresh",
        "isTablerIcon": true,
        "onActivate": function() {}
      }]
    }

    var results = []

    if (currentPath !== "" && searchQuery === "") {
      results.push({
        "name": "..",
        "description": pluginApi?.tr("result.goBack") || "Go back",
        "icon": "arrow-left",
        "isTablerIcon": true,
        "singleLine": true,
        "onActivate": function() {
          root.goBack()
        }
      })
    }

    var scored = []
    for (var i = 0; i < cachedEntries.length; i++) {
      var entry = cachedEntries[i]
      var score = fuzzyMatch(searchQuery, entry.name)
      if (score > 0) {
        scored.push({
          "entry": entry,
          "score": score
        })
      }
    }

    scored.sort(function(a, b) { return b.score - a.score })

    for (var j = 0; j < Math.min(scored.length, 50); j++) {
      var s = scored[j]
      var entryRef = s.entry
      var icon = s.entry.isDir ? "folder" : "key"
      var description = s.entry.isDir
        ? (pluginApi?.tr("result.folder") || "Folder")
        : (pluginApi?.tr("result.password") || "Password")

      results.push({
        "name": s.entry.name,
        "description": description,
        "icon": icon,
        "isTablerIcon": true,
        "singleLine": true,
        "onActivate": function() {
          var e = entryRef
          return function() {
            if (e.isDir) {
              root.navigateToPath(e.fullPath)
            } else {
              root.showPasswordOptions(e.fullPath)
            }
          }
        }()
      })
    }

    return results
  }

  function getPasswordFieldResults() {
    var results = []
    var data = root.selectedEntry.data
    var path = root.selectedEntry.path

    results.push({
      "name": path,
      "description": pluginApi?.tr("result.passwordEntry") || "Password entry",
      "icon": "key",
      "isTablerIcon": true,
      "singleLine": true,
      "onActivate": function() {}
    })

    var passEntryRef = { "path": path, "field": null }
    results.push({
      "name": pluginApi?.tr("action.copyPassword") || "Copy Password",
      "description": pluginApi?.tr("action.copyPasswordDesc") || "Copy password to clipboard",
      "icon": "copy",
      "isTablerIcon": true,
      "singleLine": true,
      "onActivate": function() {
        var e = passEntryRef
        return function() {
          root.copyField(e.path, null)
        }
      }()
    })

    results.push({
      "name": pluginApi?.tr("action.typePassword") || "Type Password",
      "description": pluginApi?.tr("action.typePasswordDesc") || "Type password using wtype",
      "icon": "typography",
      "isTablerIcon": true,
      "singleLine": true,
      "onActivate": function() {
        var e = passEntryRef
        return function() {
          root.typeField(e.path, null)
        }
      }()
    })

    for (var i = 0; i < data.fields.length; i++) {
      var field = data.fields[i]
      var fieldRef = { "path": path, "field": field }

      results.push({
        "name": pluginApi?.tr("action.copyField", { "key": field.key }) || ("Copy " + field.key),
        "description": field.value,
        "icon": "copy",
        "isTablerIcon": true,
        "singleLine": true,
        "onActivate": function() {
          var f = fieldRef
          return function() {
            root.copyField(f.path, f.field)
          }
        }()
      })

      results.push({
        "name": pluginApi?.tr("action.typeField", { "key": field.key }) || ("Type " + field.key),
        "description": field.value,
        "icon": "typography",
        "isTablerIcon": true,
        "singleLine": true,
        "onActivate": function() {
          var f = fieldRef
          return function() {
            root.typeField(f.path, f.field)
          }
        }()
      })
    }

    return results
  }

  function showPasswordOptions(path) {
    showProcPath = path
    var escapedPath = path.replace(/'/g, "'\\''")
    showProc.exec(["pass", "show", escapedPath])
  }

  function copyField(path, field) {
    var value = ""
    if (field) {
      value = field.value
    } else {
      value = root.selectedEntry ? root.selectedEntry.data.password : ""
    }

    var escapedValue = value.replace(/'/g, "'\\''")
    copyProc.exec(["sh", "-c", "printf '%s' '" + escapedValue + "' | wl-copy"])
    root.resetDetailMode()
    launcher.close()
  }

  function typeField(path, field) {
    var value = ""
    if (field) {
      value = field.value
    } else {
      value = root.selectedEntry ? root.selectedEntry.data.password : ""
    }

    var escapedValue = value.replace(/'/g, "'\\''")
    copyProc.exec(["sh", "-c", "printf '%s' '" + escapedValue + "' | wtype -"])
    root.resetDetailMode()
    launcher.close()
  }

  function resetDetailMode() {
    isDetailMode = false
    selectedEntry = null
    selectedField = null
  }
}