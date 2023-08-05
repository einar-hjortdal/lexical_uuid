# Lexical UUID

Lexicographically-sortable universally unique identifier generation. Designed to solve the problem discussed 
[here](https://www.percona.com/blog/uuids-are-popular-but-bad-for-performance-lets-discuss/)

# v1

They are a modified UUID version 7 that uses nanosecond-precision timestamps. This kind of UUID was 
proposed in the first draft-peabody-dispatch-new-uuid-format, but then discarded from the specification.

The suggested implementation was as follows:
- The first 36 bits are dedicated to the Unix Timestamp: seconds since 1st January 1970 (unixts)
- The next 12 bits are dedicated to providing sub-second encoding for the Nanosecond precision (nsec).
- The 4 Version bits conform to the UUID standard (ver).
- The next 12 bits are dedicated to providing sub-second encoding for the Nanosecond precision (nsec).
- The next 2 bits are dedicated to the Variant (var).
- The next 14 bits are dedicated to providing sub-second encoding for the Nanosecond precision (nsec).
- The next 8 bits are dedicated a monotonic clock sequence counter (seq).
- The last 40 bits are filled out with random data to pad the length and provide uniqueness (rand).

```
 0                   1                   2                   3
 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|                            unixts                             |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|unixts |         nsec          |  ver  |         nsec          |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|var|             nsec          |      seq      |     rand      |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|                             rand                              |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
```

# v2

This version includes several changes that I believe improve the specification utilized in v1:
- Dedicate 32 bits to the timestamp in seconds and adjust the start to a more recent date, January 1st 
  2020. Lexical UUIDs are not generated in the past.
- Dedicate 30 bits in total to sub-second encoding for the Nanosecond precision. This is achieved by 
  representing the nsec field as the number of nanoseconds instead of as a fraction of a second.
- The random component now has some extra bits compared to v1: 50 in total.

```
 0                   1                   2                   3
 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|                            adjts                              |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|               nsc             |  ver  |         nsc           |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|var|nsc|      seq      |                 rand                  |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|                             rand                              |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
```