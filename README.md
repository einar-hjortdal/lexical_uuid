<span style="background-color: #fed766; color: #0a080c; font-size: 125%; padding-top: 1.25%; padding-right: 2.5%; padding-bottom: 1.25%; padding-left: 2.5%; border-radius: 25px;">This project is stable: bugs are being fixed.</span>

# LUUID: Lexical Universally Unique Identifier

Optimized for databases

## v1

- The first 36 bits are dedicated to the Unix Timestamp: seconds since 1st January 1970 (unixts)
- The next 12 bits are dedicated to providing sub-second encoding for the Nanosecond precision (nsec).
- The next 4 bits are dedicated to the version (ver).
- The next 18 bits are dedicated to providing sub-second encoding for the Nanosecond precision (nsec).
- The next 8 bits are dedicated a monotonic clock sequence counter (seq).
- The last 50 bits are filled out with random data to pad the length and provide uniqueness (rand).

```
 0                   1                   2                   3
 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|                            unixts                             |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|unixts |         nsec          |  ver  |         nsec          |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|     nsec  |      seq      |               rand                |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|                             rand                              |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
```

## v2

This version is the same as the v1 but it does not contain `seq` bits.
The lack of monotonic clock sequence allows generation without a generator.

- The first 36 bits are dedicated to the Unix Timestamp: seconds since 1st January 1970 (unixts)
- The next 12 bits are dedicated to providing sub-second encoding for the Nanosecond precision (nsec).
- The next 4 bits are dedicated to the version (ver).
- The next 18 bits are dedicated to providing sub-second encoding for the Nanosecond precision (nsec).
- The last 58 bits are filled out with random data to pad the length and provide uniqueness (rand).

```
 0                   1                   2                   3
 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|                            unixts                             |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|unixts |         nsec          |  ver  |         nsec          |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|     nsec  |                       rand                        |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|                             rand                              |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
```

## Utility functions

This module also exports some utility functions for working with LUUID.
- `add_hyphens`
- `remove_hyphens`
- `parse`
- `to_bytes`
- `from_bytes`

## Database use

In FirebirdSQL, LUUID can be stored just like any UUID, using the type `BINARY(16)`.

FirebirdSQL provides functions to transform UUID from `BINARY(16)` TO `CHAR(36)` (`UUID_TO_CHAR()`) 
and the other way around (`CHAR_TO_UUID()`). These functions work correctly with LUUID.

This library provides the utility functions `to_bytes` and `from_bytes`.
- `to_bytes` transforms a luuid `string` into a `[]u8`
- `from_bytes` transforms a luuid `[]u8` to a `string`
With these you can bind and retrieve `[]u8` to and from `BINARY(16)` columns. No more `SELECT UUID_TO_CHAR(...)` 
and `INSERT CHAR_TO_UUID(...)` in your queries.

## Lore

Originally an implementation [this proposed UUIDv7 design](https://www.ietf.org/archive/id/draft-peabody-dispatch-new-uuid-format-01.html#name-uuidv7-field-and-bit-layout-en). Subsequently, this design was scrapped, and the final UUIDv7 design was implemented in [vlib](https://modules.vlang.io/rand.html#uuid_v7). This change prompted me to deviate from the original structure to gain 10 bits of uniqueness guarantees. I achieved this by removing the 2 variant bits and the 8 fractional nanosecond bits [as discussed here](https://github.com/uuid6/uuid6-ietf-draft/issues/24), This modification still maintains full UUID compatibility with FirebirdSQL's `UUID_TO_CHAR()` and `CHAR_TO_UUID()` functions.
