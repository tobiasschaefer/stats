//
//  settings.swift
//  Stats
//
//  Created by Serhiy Mytrovtsiy on 23/06/2020.
//  Using Swift 5.0.
//  Running on macOS 10.15.
//
//  Copyright © 2020 Serhiy Mytrovtsiy. All rights reserved.
//

import Cocoa
import StatsKit
import ModuleKit

internal class Settings: NSView, Settings_v {
    private let title: String
    private let store: UnsafePointer<Store>
    private var button: NSPopUpButton?
    private let list: UnsafeMutablePointer<[Sensor_t]>
    public var callback: (() -> Void) = {}
    
    public init(_ title: String, store: UnsafePointer<Store>, list: UnsafeMutablePointer<[Sensor_t]>) {
        self.title = title
        self.store = store
        self.list = list
        super.init(frame: CGRect(x: Constants.Settings.margin, y: Constants.Settings.margin, width: Constants.Settings.width - (Constants.Settings.margin*2), height: 0))
        self.wantsLayer = true
        self.canDrawConcurrently = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func load(widget: widget_t) {
        guard !self.list.pointee.isEmpty else {
            return
        }
        self.subviews.forEach{ $0.removeFromSuperview() }
        
        var types: [SensorType_t: Int] = [:]
        self.list.pointee.forEach { (s: Sensor_t) in
            types[s.type] = (types[s.type] ?? 0) + 1
        }
        
        let rowHeight: CGFloat = 30
        let height: CGFloat = ((rowHeight+Constants.Settings.margin) * CGFloat(self.list.pointee.count)) + ((rowHeight+Constants.Settings.margin) * CGFloat(types.count))
        let x: CGFloat = height < 360 ? 0 : Constants.Settings.margin
        let view: NSView = NSView(frame: NSRect(x: Constants.Settings.margin, y: Constants.Settings.margin, width: self.frame.width - (Constants.Settings.margin*2) - x, height: height))
        
        var y: CGFloat = 0
        types.sorted{ $0.1 < $1.1 }.forEach { (t: (key: SensorType_t, value: Int)) in
            let filtered = self.list.pointee.filter{ $0.type == t.key }
            var groups: [SensorGroup_t: Int] = [:]
            filtered.forEach { (s: Sensor_t) in
                groups[s.group] = (groups[s.group] ?? 0) + 1
            }
            
            groups.sorted{ $0.1 < $1.1 }.forEach { (g: (key: SensorGroup_t, value: Int)) in
                filtered.reversed().filter{ $0.group == g.key }.forEach { (s: Sensor_t) in
                    let row: NSView = ToggleTitleRow(
                        frame: NSRect(x: 0, y: y, width: view.frame.width, height: rowHeight),
                        title: s.name,
                        action: #selector(self.handleSelection),
                        state: s.state
                    )
                    row.subviews.filter{ $0 is NSControl }.forEach { (control: NSView) in
                        control.identifier = NSUserInterfaceItemIdentifier(rawValue: s.key)
                    }
                    view.addSubview(row)
                    y += rowHeight + Constants.Settings.margin
                }
            }
            
            let rowTitleView: NSView = NSView(frame: NSRect(x: 0, y: y, width: view.frame.width, height: rowHeight))
            let rowTitle: NSTextField = LabelField(frame: NSRect(x: 0, y: (rowHeight-19)/2, width: view.frame.width, height: 19), t.key)
            rowTitle.font = NSFont.systemFont(ofSize: 14, weight: .regular)
            rowTitle.textColor = .secondaryLabelColor
            rowTitle.alignment = .center
            rowTitleView.addSubview(rowTitle)
            
            view.addSubview(rowTitleView)
            y += rowHeight + Constants.Settings.margin
        }
        
        self.addSubview(view)
        self.setFrameSize(NSSize(width: self.frame.width, height: height + (Constants.Settings.margin*1)))
    }
    
    @objc func handleSelection(_ sender: NSControl) {
        guard let id = sender.identifier else { return }
        
        var state: NSControl.StateValue? = nil
        if #available(OSX 10.15, *) {
            state = sender is NSSwitch ? (sender as! NSSwitch).state: nil
        } else {
            state = sender is NSButton ? (sender as! NSButton).state: nil
        }
        
        self.store.pointee.set(key: "sensor_\(id.rawValue)", value:  state! == NSControl.StateValue.on)
        self.callback()
    }
}
