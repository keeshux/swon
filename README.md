# SWON

Foundation-free Swift/JSON processing.

## Purpose

SWON is a tiny set of [Swift Macros][swift-macros] that extend value types with simplified JSON processing without the need for `Codable` or the Foundation framework.

SWON is part of my "fight" against Swift dependencies [outside of the Apple ecosystem][web-cps] and uses the amazingly written [cJSON][credits-cjson] parser under the hood.

### Caveats

- Dictionary keys must be `String`.
- Optionals in collections (e.g. `[Int?]`) are not supported.

### TODO

- Add encoding Swift to JSON.
- Enums with associated types.

## License

Copyright (c) 2025 Davide De Rosa. All rights reserved.

This project is licensed under the [MIT][license-content].

## Contacts

Twitter: [@keeshux][about-twitter]

Website: [davidederosa.com][web-home]

[license-content]: LICENSE
[swift-macros]: https://docs.swift.org/swift-book/documentation/the-swift-programming-language/macros/
[credits-cjson]: https://github.com/DaveGamble/cJSON
[web-home]: https://davidederosa.com
[web-cps]: https://davidederosa.com/cross-platform-swift/
[about-twitter]: https://twitter.com/keeshux
