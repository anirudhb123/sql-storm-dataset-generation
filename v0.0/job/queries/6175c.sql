SELECT min(mi_idx.info) AS rating, min(t.title) AS movie_title
FROM info_type AS it, keyword AS k, movie_info_idx AS mi_idx, movie_keyword AS mk, title AS t
WHERE t.id = mi_idx.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi_idx.movie_id AND k.id = mk.keyword_id AND it.id = mi_idx.info_type_id
AND mi_idx.info > '57877' AND mi_idx.movie_id < 1728900 AND k.phonetic_code LIKE '%56%' AND t.production_year > 1923 AND t.phonetic_code LIKE '%24%';