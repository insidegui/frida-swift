# frida-swift

Swift bindings for [Frida](https://frida.re).

## Install - macOS

- Build Frida for your Mac, e.g. `make core-macos`
- Generate a devkit:

    ./releng/devkit.py frida-core macos-x86_64 ./frida-swift/CFrida/

- Open and build with Xcode.

## Install - macOS + iOS (experimental)

- Get the latest `frida-core` devkit from [here](https://github.com/frida/frida/releases)
- Download both Mac and iOS arm64e `frida-core` devkits (at the time of writing, `frida-core-devkit-16.2.1-macos-arm64e` and `frida-core-devkit-16.2.1-ios-arm64e`)
- Extract the packages
- Move `frida-core.h` header within each platform directory to a new directory, like `headers`
- Package both as a `xcframework`:

```
xcodebuild -create-xcframework \
    -library ./frida-core-devkit-16.2.1-ios-arm64e/libfrida-core.a \
    -headers ./frida-core-devkit-16.2.1-ios-arm64e/headers \
    -library ./frida-core-devkit-16.2.1-macos-arm64e/libfrida-core.a \
    -headers ./frida-core-devkit-16.2.1-macos-arm64e/headers \
    -output ./FridaCore.xcframework
```

- Within each `Headers` directory inside the generated `xcframework`, create a `module.modulemap` file with the following contents:

```
module CFrida {
    header "frida-core.h"
    export *
}
```

## Example

```swift
func testFullCycle() {
    let pid: UInt = 20854

    let expectation = self.expectation(description: "Got message from script")

    class TestDelegate : ScriptDelegate {
        let expectation: XCTestExpectation
        var messages: [Any] = []

        init(expectation: XCTestExpectation) {
            self.expectation = expectation
        }

        func scriptDestroyed(_: Script) {
            print("destroyed")
        }

        func script(_: Script, didReceiveMessage message: Any, withData data: Data?) {
            print("didReceiveMessage")
            messages.append(message)
            if messages.count == 2 {
                expectation.fulfill()
            }
        }
    }
    let delegate = TestDelegate(expectation: expectation)

    let manager = DeviceManager()
    var script: Script? = nil
    manager.enumerateDevices { result in
        let devices = try! result()
        let localDevice = devices.filter { $0.kind == Device.Kind.local }.first!
        localDevice.attach(to: pid) { result in
            let session = try! result()
            session.createScript("console.log(\"hello\"); send(1337);") { result in
                let s = try! result()
                s.delegate = delegate
                s.load() { result in
                    _ = try! result()
                    print("Script loaded")
                }
                script = s
            }
        }
    }

    self.waitForExpectations(timeout: 5.0, handler: nil)
    print("Done with script \(script), messages: \(delegate.messages)")
}
```
