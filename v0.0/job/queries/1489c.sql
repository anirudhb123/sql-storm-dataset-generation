SELECT min(mi_idx.info) AS rating, min(t.title) AS movie_title
FROM info_type AS it, keyword AS k, movie_info_idx AS mi_idx, movie_keyword AS mk, title AS t
WHERE t.id = mi_idx.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi_idx.movie_id AND k.id = mk.keyword_id AND it.id = mi_idx.info_type_id
AND mk.keyword_id < 18773 AND t.title > 'Whose Life Is It?' AND t.phonetic_code > 'D3532' AND mi_idx.info_type_id IN (100, 101, 112, 113, 99) AND t.md5sum IS NOT NULL AND t.season_nr IS NOT NULL;