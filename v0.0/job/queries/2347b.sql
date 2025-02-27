SELECT min(mi_idx.info) AS rating, min(t.title) AS movie_title
FROM info_type AS it, keyword AS k, movie_info_idx AS mi_idx, movie_keyword AS mk, title AS t
WHERE t.id = mi_idx.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi_idx.movie_id AND k.id = mk.keyword_id AND it.id = mi_idx.info_type_id
AND t.md5sum IN ('0aa0c05314e195f9c0a2e16edd959301', '295f21dbe552e6bbb8903d4f7273c01f', '33b7ec90cbd934c56341c2ed7db95579', '55b023da02c2a250d78c2c72b73e772c', 'b212d73901f7593dc389d5ba96ca9f21');