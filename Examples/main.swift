import SWON

@SWON
struct Foobar {
    let num: Int
    let str: String
}

let json = """
{
    "num": 123,
    "str": "This is a string"
}
"""

let obj = try Foobar(fromJSON: json)
print(obj)
