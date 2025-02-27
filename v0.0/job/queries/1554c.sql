SELECT min(t.title) AS movie_title
FROM keyword AS k, movie_info AS mi, movie_keyword AS mk, title AS t
WHERE t.id = mi.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi.movie_id AND k.id = mk.keyword_id
AND t.production_year IN (1907, 1909, 1998, 2005, 2009) AND k.phonetic_code < 'S1561' AND mi.id < 6009308 AND k.keyword IN ('argentine-filmmaking', 'epilepsy', 'israeli-olympic-team', 'reference-to-lewis-carroll', 'security-guard-shot-in-the-chest', 'soceroos', 'sucking-on-a-finger', 'vivisection');