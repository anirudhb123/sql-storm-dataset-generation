SELECT min(mi_idx.info) AS rating, min(t.title) AS movie_title
FROM info_type AS it, keyword AS k, movie_info_idx AS mi_idx, movie_keyword AS mk, title AS t
WHERE t.id = mi_idx.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi_idx.movie_id AND k.id = mk.keyword_id AND it.id = mi_idx.info_type_id
AND k.keyword IN ('confession-note', 'gunmetal', 'knifed-to-death', 'logo', 'mass-murder', 'reference-to-marc-andrew-"pete"-mitscher', 'reference-to-terry-gilliam', 'remake-of-spanish-film', 'thematic-cinema', 'vietnamese-man') AND t.season_nr > 1 AND t.id < 989084;