SELECT min(mi_idx.info) AS rating, min(t.title) AS movie_title
FROM info_type AS it, keyword AS k, movie_info_idx AS mi_idx, movie_keyword AS mk, title AS t
WHERE t.id = mi_idx.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi_idx.movie_id AND k.id = mk.keyword_id AND it.id = mi_idx.info_type_id
AND t.episode_nr < 1729 AND t.phonetic_code < 'F6156' AND t.season_nr < 2007 AND k.keyword IN ('athletic-scholarship', 'exploding-man', 'florianópolis', 'kaishi', 'marital-law', 'new-york-times-bestseller', 'reichstag', 'sardine', 'solo-flight', 'swear');