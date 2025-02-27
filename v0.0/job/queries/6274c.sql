SELECT min(mi_idx.info) AS rating, min(t.title) AS movie_title
FROM info_type AS it, keyword AS k, movie_info_idx AS mi_idx, movie_keyword AS mk, title AS t
WHERE t.id = mi_idx.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi_idx.movie_id AND k.id = mk.keyword_id AND it.id = mi_idx.info_type_id
AND t.md5sum IN ('45070e2e1bcdc580b010b52faef9ef15', '953c85e793ba1929815495d7e559b5fe', 'aff02138c91842fbf86283a50053af1f');