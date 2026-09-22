import XCTest
import Defaults
import SwiftData
@testable import Maccy

@MainActor
class HistoryTests: XCTestCase { // swiftlint:disable:this type_body_length
  let savedSize = Defaults[.size]
  let savedSortBy = Defaults[.sortBy]
  let savedPinTo = Defaults[.pinTo]
  let history = History.shared

  override func setUp() {
    super.setUp()
    history.clearAll()
    Defaults[.size] = 10
    Defaults[.sortBy] = .firstCopiedAt
    Defaults[.pinTo] = .bottom
  }

  override func tearDown() {
    super.tearDown()
    Defaults[.size] = savedSize
    Defaults[.sortBy] = savedSortBy
    Defaults[.pinTo] = savedPinTo
  }

  func testDefaultIsEmpty() {
    XCTAssertEqual(history.items, [])
  }

  func testAdding() {
    let first = history.add(historyItem("foo"))
    let second = history.add(historyItem("bar"))
    XCTAssertEqual(history.items, [second, first])
  }

  func testAddingPersistedDuplicate() throws {
    let first = historyItem("foo")
    first.title = "xyz"
    first.application = "iTerm.app"
    history.add(first)
    first.pin = "f"

    let third = historyItem("foo")
    third.application = "Xcode.app"
    let transferredContents = first.contents
    let merged = history.add(third)

    XCTAssertEqual(history.all, [merged])
    XCTAssertEqual(Set(merged.item.contents), Set(transferredContents))
    XCTAssertTrue(merged.item.lastCopiedAt > merged.item.firstCopiedAt)
    XCTAssertEqual(merged.item.numberOfCopies, 2)
    XCTAssertEqual(merged.item.pin, "f")
    XCTAssertEqual(merged.item.title, "xyz")
    XCTAssertEqual(merged.item.application, "iTerm.app")
    try assertStorageCounts(items: 1, contents: 1)
  }

  func testAddingUnsavedDuplicate() throws {
    guard #available(macOS 15.0, *) else {
      throw XCTSkip("Incoming history items are inserted before add on macOS 14")
    }

    let first = historyItem("foo")
    first.title = "xyz"
    first.application = "iTerm.app"
    history.add(first)
    first.pin = "f"

    let second = historyItem("foo", persisted: false)
    second.application = "Xcode.app"
    let transferredContents = first.contents
    let merged = history.add(second)

    XCTAssertEqual(history.all, [merged])
    XCTAssertEqual(Set(merged.item.contents), Set(transferredContents))
    XCTAssertTrue(merged.item.lastCopiedAt > merged.item.firstCopiedAt)
    XCTAssertEqual(merged.item.numberOfCopies, 2)
    XCTAssertEqual(merged.item.pin, "f")
    XCTAssertEqual(merged.item.title, "xyz")
    XCTAssertEqual(merged.item.application, "iTerm.app")
    try assertStorageCounts(items: 1, contents: 1)
  }

  func testAddingItemThatIsSupersededByExisting() throws {
    let firstContents = [
      HistoryItemContent(
        type: NSPasteboard.PasteboardType.string.rawValue,
        value: "one".data(using: .utf8)!
      ),
      HistoryItemContent(
        type: NSPasteboard.PasteboardType.rtf.rawValue,
        value: "two".data(using: .utf8)!
      )
    ]
    let firstItem = HistoryItem()
    Storage.shared.context.insert(firstItem)
    firstItem.application = "Maccy.app"
    firstItem.contents = firstContents
    firstItem.title = firstItem.generateTitle()
    history.add(firstItem)

    let secondContents = [
      HistoryItemContent(
        type: NSPasteboard.PasteboardType.string.rawValue,
        value: "one".data(using: .utf8)!
      )
    ]
    let secondItem = HistoryItem()
    Storage.shared.context.insert(secondItem)
    secondItem.application = "Maccy.app"
    secondItem.contents = secondContents
    secondItem.title = secondItem.generateTitle()
    let second = history.add(secondItem)

    XCTAssertEqual(history.items, [second])
    XCTAssertEqual(Set(history.items[0].item.contents), Set(firstContents))
    try assertStorageCounts(items: 1, contents: firstContents.count)
  }

  func testAddingItemWithDifferentModifiedType() {
    let firstContents = [
      HistoryItemContent(
        type: NSPasteboard.PasteboardType.string.rawValue,
        value: "one".data(using: .utf8)!
      ),
      HistoryItemContent(
        type: NSPasteboard.PasteboardType.modified.rawValue,
        value: "1".data(using: .utf8)!
      )
    ]
    let firstItem = HistoryItem()
    Storage.shared.context.insert(firstItem)
    firstItem.contents = firstContents
    history.add(firstItem)

    let secondContents = [
      HistoryItemContent(
        type: NSPasteboard.PasteboardType.string.rawValue,
        value: "one".data(using: .utf8)!
      ),
      HistoryItemContent(
        type: NSPasteboard.PasteboardType.modified.rawValue,
        value: "2".data(using: .utf8)!
      )
    ]
    let secondItem = HistoryItem()
    Storage.shared.context.insert(secondItem)
    secondItem.contents = secondContents
    let second = history.add(secondItem)

    XCTAssertEqual(history.items, [second])
    XCTAssertEqual(Set(history.items[0].item.contents), Set(firstContents))
  }

  func testAddingItemFromMaccy() {
    let firstContents = [
      HistoryItemContent(
        type: NSPasteboard.PasteboardType.string.rawValue,
        value: "one".data(using: .utf8)
      )
    ]
    let first = HistoryItem()
    Storage.shared.context.insert(first)
    first.application = "Xcode.app"
    first.contents = firstContents
    history.add(first)

    let secondContents = [
      HistoryItemContent(
        type: NSPasteboard.PasteboardType.string.rawValue,
        value: "one".data(using: .utf8)
      ),
      HistoryItemContent(
        type: NSPasteboard.PasteboardType.fromMaccy.rawValue,
        value: "".data(using: .utf8)
      )
    ]
    let second = HistoryItem()
    Storage.shared.context.insert(second)
    second.application = "Maccy.app"
    second.contents = secondContents
    let secondDecorator = history.add(second)

    XCTAssertEqual(history.items, [secondDecorator])
    XCTAssertEqual(history.items[0].item.application, "Xcode.app")
    XCTAssertEqual(Set(history.items[0].item.contents), Set(firstContents))
  }

  func testModifiedAfterCopying() {
    history.add(historyItem("foo"))

    let modifiedItem = historyItem("bar")
    modifiedItem.contents.append(HistoryItemContent(
      type: NSPasteboard.PasteboardType.modified.rawValue,
      value: String(Clipboard.shared.changeCount).data(using: .utf8)
    ))
    let modifiedItemDecorator = history.add(modifiedItem)

    XCTAssertEqual(history.items, [modifiedItemDecorator])
    XCTAssertEqual(history.items[0].text, "bar")
  }

  func testClearingUnpinned() throws {
    let pinned = history.add(historyItem("foo"))
    pinned.togglePin()
    history.add(historyItem("bar"))
    let orphan = HistoryItemContent(
      type: NSPasteboard.PasteboardType.string.rawValue,
      value: "orphan".data(using: .utf8)
    )
    Storage.shared.context.insert(orphan)
    try Storage.shared.context.save()

    history.clear()

    XCTAssertEqual(history.items, [pinned])
    try assertStorageCounts(items: 1, contents: 1)
  }

  func testClearingAll() throws {
    history.add(historyItem("foo"))
    let pinned = history.add(historyItem("bar"))
    pinned.togglePin()
    Storage.shared.context.insert(HistoryItemContent(
      type: NSPasteboard.PasteboardType.string.rawValue,
      value: "orphan".data(using: .utf8)
    ))
    try Storage.shared.context.save()

    history.clearAll()

    XCTAssertEqual(history.items, [])
    try assertStorageCounts(items: 0, contents: 0)
  }

  func testMaxSize() throws {
    var items: [HistoryItemDecorator] = []
    for index in 0...10 {
      items.append(history.add(historyItem(String(index))))
    }

    XCTAssertEqual(history.items.count, 10)
    XCTAssertTrue(history.items.contains(items[10]))
    XCTAssertFalse(history.items.contains(items[0]))
    try assertStorageCounts(items: 10, contents: 10)
  }

  func testMaxSizeIgnoresPinned() {
    var items: [HistoryItemDecorator] = []

    let item = history.add(historyItem("0"))
    items.append(item)
    item.togglePin()

    for index in 1...11 {
      items.append(history.add(historyItem(String(index))))
    }

    XCTAssertEqual(history.items.count, 11)
    XCTAssertTrue(history.items.contains(items[10]))
    XCTAssertTrue(history.items.contains(items[0]))
    XCTAssertFalse(history.items.contains(items[1]))
  }

  func testMaxSizeIsChanged() {
    var items: [HistoryItemDecorator] = []
    for index in 0...10 {
      items.append(history.add(historyItem(String(index))))
    }
    Defaults[.size] = 5
    history.add(historyItem("11"))

    XCTAssertEqual(history.items.count, 5)
    XCTAssertTrue(history.items.contains(items[10]))
    XCTAssertFalse(history.items.contains(items[5]))
  }

  func testReaddingBottomMostPinnedItemAtFullCapacity() {
    // Regression test for a crash when re-copying (invoking) the bottom-most
    // pinned item while history is at full capacity and pins are sorted to the
    // bottom. The stale insert index used to trap with an out-of-bounds insert.
    // Issue link: https://github.com/p0deje/Maccy/issues/1466
    // `pinTo` is restored to its default value(.top) in `tearDown`.
    Defaults[.pinTo] = .bottom

    // Pin an item; `history.togglePin` re-sorts `all`, so with `.bottom` the
    // pinned item ends up as the last element.
    let pinned = history.add(historyItem("pinned"))
    history.togglePin(pinned)

    // Fill unpinned history to full capacity.
    for index in 0..<Defaults[.size] {
      history.add(historyItem(String(index)))
    }

    XCTAssertEqual(history.all.last, pinned)

    // Re-copy the pinned item. It is detected as a duplicate, removed and
    // re-inserted while `limitHistorySize` trims an exceeding unpinned item.
    // Before the fix this inserted at a stale, out-of-bounds index and crashed.
    let readded = history.add(historyItem("pinned"))

    XCTAssertTrue(history.all.contains(readded))
    XCTAssertEqual(history.all.filter(\.isPinned).count, 1)
  }

  func testRemoving() throws {
    let foo = history.add(historyItem("foo"))
    let bar = history.add(historyItem("bar"))
    history.delete(foo)
    XCTAssertEqual(history.items, [bar])
    try assertStorageCounts(items: 1, contents: 1)
  }

  func testUnlimitedSize() {
    Defaults[.size] = 0
    var items: [HistoryItemDecorator] = []
    for index in 0...14 {
      items.append(history.add(historyItem(String(index))))
    }
    XCTAssertEqual(history.items.count, 15)
    XCTAssertTrue(history.items.contains(items[0]))
    XCTAssertTrue(history.items.contains(items[14]))
  }

  func testUnlimitedSizeSurvivesReload() async throws {
    Defaults[.size] = 0
    for index in 0..<15 {
      history.add(historyItem(String(index)))
    }
    try await history.load()
    XCTAssertEqual(history.items.count, 15)
    try assertStorageCounts(items: 15, contents: 15)
  }

  func testReloadOfLargeHistoryKeepsNewestItemsAndPins() async throws {
    let context = Storage.shared.context
    for index in 0..<3_000 {
      let item = historyItem(String(index))
      item.firstCopiedAt = Date(timeIntervalSince1970: TimeInterval(index))
    }
    for pin in ["b", "c", "d"] {
      let item = historyItem("pinned-\(pin)")
      item.pin = pin
    }
    try context.save()

    Defaults[.size] = 0
    try await history.load()
    XCTAssertEqual(history.all.count, 3_003)

    Defaults[.size] = 999
    let started = Date()
    try await history.load()
    let elapsed = Date().timeIntervalSince(started)
    print("Large-history reload: \(elapsed) seconds")
    XCTAssertLessThan(elapsed, 10, "Reloading an oversized store must not freeze startup")
    XCTAssertEqual(history.unpinnedItems.map(\.title), (2_001..<3_000).reversed().map(String.init))
    XCTAssertEqual(Set(history.pinnedItems.compactMap { $0.item.pin }), Set(["b", "c", "d"]))
    try assertStorageCounts(items: 1_002, contents: 1_002)

    try await history.load()
    XCTAssertEqual(history.all.count, 1_002)
    try assertStorageCounts(items: 1_002, contents: 1_002)
  }

  func testSizeOneKeepsOnlyNewestUnpinnedItem() throws {
    Defaults[.size] = 1
    let pinned = history.add(historyItem("pinned"))
    history.togglePin(pinned)
    history.add(historyItem("old"))
    let newest = history.add(historyItem("new"))

    XCTAssertEqual(history.unpinnedItems, [newest])
    XCTAssertEqual(history.pinnedItems, [pinned])
    try assertStorageCounts(items: 2, contents: 2)
  }

  func testRecopyingPinnedItemPreservesFullUnpinnedHistory() throws {
    Defaults[.size] = 2
    let pinned = history.add(historyItem("pinned"))
    history.togglePin(pinned)
    history.add(historyItem("one"))
    history.add(historyItem("two"))
    let unpinned = history.unpinnedItems

    history.add(historyItem("pinned"))

    XCTAssertEqual(history.all.filter(\.isUnpinned), unpinned)
    try assertStorageCounts(items: 3, contents: 3)
  }

  func testMultiSelectionExtendsAndToggles() {
    XCTAssertTrue(AppState.shared.multiSelectionEnabled)
    history.add(historyItem("one"))
    history.add(historyItem("two"))
    history.add(historyItem("three"))
    let items = history.items
    let navigator = NavigationManager(history: history, footer: Footer())

    navigator.select(item: items[0])
    navigator.extendHighlightToNext()
    XCTAssertEqual(navigator.selection.items, Array(items.prefix(2)))
    XCTAssertTrue(navigator.isMultiSelectInProgress)
    navigator.addToSelection(item: items[2])
    XCTAssertEqual(navigator.selection.items, items)
    navigator.addToSelection(item: items[1])
    XCTAssertEqual(navigator.selection.items, [items[0], items[2]])
  }

  func testSanitizingStoredTitlesPreservesClipboardContents() throws {
    let value = "before\u{FFFC}after"
    let item = history.add(historyItem(value))
    history.togglePin(item)
    item.item.title = value
    let contents = item.item.contents
    let pin = item.item.pin

    XCTAssertEqual(try Storage.shared.sanitizeTitles(), 1)
    XCTAssertEqual(item.item.title, "beforeafter")
    XCTAssertEqual(item.item.contents, contents)
    XCTAssertEqual(item.item.contents.first?.value, value.data(using: .utf8))
    XCTAssertEqual(item.item.pin, pin)
    XCTAssertEqual(try Storage.shared.sanitizeTitles(), 0)
    try assertStorageCounts(items: 1, contents: 1)
  }

  func testCleaningUpOrphanedContents() throws {
    let live = history.add(historyItem("live"))
    let liveContent = live.item.contents[0]
    for value in ["orphan-1", "orphan-2"] {
      Storage.shared.context.insert(HistoryItemContent(
        type: NSPasteboard.PasteboardType.string.rawValue,
        value: value.data(using: .utf8)
      ))
    }
    try Storage.shared.context.save()

    XCTAssertEqual(try Storage.shared.cleanupOrphanedContents(), 2)
    XCTAssertEqual(try Storage.shared.cleanupOrphanedContents(), 0)
    XCTAssertEqual(live.item.contents, [liveContent])
    try assertStorageCounts(items: 1, contents: 1)
  }

  private func assertStorageCounts(
    items: Int,
    contents: Int,
    orphaned: Int = 0,
    file: StaticString = #filePath,
    line: UInt = #line
  ) throws {
    let context = Storage.shared.context
    context.processPendingChanges()
    try context.save()
    XCTAssertEqual(
      try context.fetchCount(FetchDescriptor<HistoryItem>()),
      items,
      file: file,
      line: line
    )
    XCTAssertEqual(
      try context.fetchCount(FetchDescriptor<HistoryItemContent>()),
      contents,
      file: file,
      line: line
    )
    XCTAssertEqual(
      try context.fetchCount(FetchDescriptor<HistoryItemContent>(
        predicate: #Predicate { $0.item == nil }
      )),
      orphaned,
      file: file,
      line: line
    )
  }

  private func historyItem(_ value: String, persisted: Bool = true) -> HistoryItem {
    let contents = [
      HistoryItemContent(
        type: NSPasteboard.PasteboardType.string.rawValue,
        value: value.data(using: .utf8)
      )
    ]
    let item = HistoryItem()
    if persisted {
      Storage.shared.context.insert(item)
    }
    item.contents = contents
    item.numberOfCopies = 1
    item.title = item.generateTitle()

    return item
  }
}
