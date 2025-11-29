# SWON

Foundation-free Swift/JSON processing.

SWON is a tiny set of [Swift Macros][swift-macros] that extend value types with simplified JSON processing without the need for `Codable` or the Foundation framework.

SWON should work on every supported Swift platform. Tested on Apple, Android, Linux, and Windows.

## Usage

Dead easy. Attach the macro to any `struct` or `enum`:

```swift
import SWON

@SWON
enum Color {
	case red, green blue
}

@SWON
struct Foobar {
	let numField: Int
	let stringArray: [String]
	let myDictionary: [String: [Double]]
	let innerStructs: [[CustomStruct]]
	let namedList: [Color]?
}
```

And you'll get a new initializer:

```swift
let foobar = try Foobar(fromJSON: """
{
	"numField": 100,
	"stringArray": ["one", "two", "three"]
	...
}
""")
```

## Why?

SWON is part of an ongoing "fight" against Swift dependencies [outside of the Apple ecosystem][web-cps], whose goal is making my app, [Passepartout][github-passepartout], natively cross-platform with Swift.

If you only use Swift on Apple platforms, you won't find this package very useful, if at all. `JSONEncoder` and `JSONDecoder` offer such a thorough feature set that SWON doesn't even try to replace them.

Instead, it serves the single purpose of parsing complex value types with a tiny footprint, because it doesn't rely on Foundation. In fact, SWON doesn't even use `Codable`, thus making it a future candidate for [Embedded Swift][swift-embedded], where `Codable` is unavailable.

Last but not least, it was an entertaining exercise to get familiar with [Swift Macros][swift-macros].

SWON uses the amazingly written [cJSON][credits-cjson] parser (C) under the hood.
 
## Caveats

### Restrictions

- Dictionary keys must be `String`.
- Optionals in collections (e.g. `[Int?]`) are not supported.

### Things to do

- Encode Swift to JSON (decode-only for now).
- Enums with associated types.

## License

Copyright (c) 2025 Davide De Rosa. All rights reserved.

This project is licensed under the [MIT][license-content].

## Contacts

Twitter: [@keeshux][about-twitter]

Website: [davidederosa.com][web-home], with my blog series on [cross-platform Swift][web-cps].

[license-content]: LICENSE
[swift-macros]: https://docs.swift.org/swift-book/documentation/the-swift-programming-language/macros/
[swift-embedded]: https://www.swift.org/get-started/embedded/
[credits-cjson]: https://github.com/DaveGamble/cJSON
[web-home]: https://davidederosa.com
[web-cps]: https://davidederosa.com/cross-platform-swift/
[github-passepartout]: https://github.com/partout-io/passepartout
[about-twitter]: https://twitter.com/keeshux
