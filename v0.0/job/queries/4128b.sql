SELECT min(t.title) AS movie_title
FROM keyword AS k, movie_info AS mi, movie_keyword AS mk, title AS t
WHERE t.id = mi.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi.movie_id AND k.id = mk.keyword_id
AND t.md5sum IN ('0bfc351964cce7f90b3e58054d99ae42', '21df001af6b028c30d9062b0d67c89ea', '4915f3503e62b70063a6d42cca0799dc', '53dda193309887ed17ce5711bc473fdd', '5c5bc8387fcb6f9e00d6e792921a2aa5', 'db9f92940279b74c01aa31970a5f2b84');