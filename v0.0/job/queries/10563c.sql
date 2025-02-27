SELECT min(t.title) AS movie_title
FROM keyword AS k, movie_info AS mi, movie_keyword AS mk, title AS t
WHERE t.id = mi.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi.movie_id AND k.id = mk.keyword_id
AND t.phonetic_code LIKE '%J%' AND t.production_year IS NOT NULL AND t.id > 223413 AND mi.note IN ('(Hiking Scene)', '(Kodak Ektachrome 64D 5017, Eastman Ektachrome 160D 5239, Vision 500T 5279)', '(PCA #15765)', 'OWN: Oprah Winfrey Network US', 'Sherman (courtesy of Broadway.com)');