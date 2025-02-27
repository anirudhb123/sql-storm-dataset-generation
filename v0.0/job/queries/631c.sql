SELECT min(mi_idx.info) AS rating, min(t.title) AS movie_title
FROM info_type AS it, keyword AS k, movie_info_idx AS mi_idx, movie_keyword AS mk, title AS t
WHERE t.id = mi_idx.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi_idx.movie_id AND k.id = mk.keyword_id AND it.id = mi_idx.info_type_id
AND k.keyword IN ('2004-indian-ocean-earthquake-and-tsunami', 'alien-conspiracy', 'boxing-on-tv', 'heroin-addict', 'moody-south-carolina', 'reference-to-a-farewell-to-arms-the-novel', 'split-croatia') AND it.info > 'biographical movies';