SELECT min(mi_idx.info) AS rating, min(t.title) AS movie_title
FROM info_type AS it, keyword AS k, movie_info_idx AS mi_idx, movie_keyword AS mk, title AS t
WHERE t.id = mi_idx.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi_idx.movie_id AND k.id = mk.keyword_id AND it.id = mi_idx.info_type_id
AND t.episode_of_id IS NOT NULL AND t.kind_id > 4 AND k.keyword > 'reference-to-richard-dix' AND k.id IN (130978, 19203, 43758, 51730, 64683, 67636);