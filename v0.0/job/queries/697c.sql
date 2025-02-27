SELECT min(mi_idx.info) AS rating, min(t.title) AS movie_title
FROM info_type AS it, keyword AS k, movie_info_idx AS mi_idx, movie_keyword AS mk, title AS t
WHERE t.id = mi_idx.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi_idx.movie_id AND k.id = mk.keyword_id AND it.id = mi_idx.info_type_id
AND it.info > 'LD sound encoding' AND t.title > 'Jeffrey Archer: The Truth' AND mi_idx.info IN ('....1.1.25', '....231..3', '...13111.3', '..0..124.0', '..1.1114.1', '..1.312..2', '.001311000', '1..02202.0', '1..53.....', '2..1.222.1') AND k.keyword < 'green-religion';