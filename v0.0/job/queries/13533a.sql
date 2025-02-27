SELECT min(t.title) AS movie_title
FROM keyword AS k, movie_info AS mi, movie_keyword AS mk, title AS t
WHERE t.id = mi.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi.movie_id AND k.id = mk.keyword_id
AND t.md5sum IN ('07cb7da161f2ab4ea683c59e02b076aa', '4bf8e798270f66d6a98adca1c9b10f78') AND t.phonetic_code > 'M4624';