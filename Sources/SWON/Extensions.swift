// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: MIT

extension Array: SWONDecodable, SWONEncodable where Element: SWONDecodable & SWONEncodable {
    public init(fromSWON root: swon_t) throws {
        var list: [Element] = []
        var array = swon_t()
        guard swon_get_array(&array, root) == SWONResultValid else {
            throw SWONError.required("Array")
        }
        let size = swon_get_array_size(array)
        for i in 0..<size {
            var item = swon_t()
            let result = swon_get_array_item(&item, array, Int32(i))
            guard result == SWONResultValid else { throw SWONError.invalid("Array") }
            let el = try Element(fromSWON: item)
            list.append(el)
        }
        self = list
    }

    public func toSWON() throws -> swon_t {
        let list = Array(self)
        var root = swon_t()
        guard swon_create_array(&root) else { throw SWONError.invalid("Array") }
        for el in list {
            let item = try el.toSWON()
            guard swon_array_add_item(&root, item) else {
                throw SWONError.invalid("Array: Element")
            }
        }
        return root
    }
}

extension Set: SWONDecodable, SWONEncodable where Element: SWONDecodable & SWONEncodable {
    public init(fromSWON root: swon_t) throws {
        self = try Set(Array(fromSWON: root))
    }

    public func toSWON() throws -> swon_t {
        try Array(self).toSWON()
    }
}
