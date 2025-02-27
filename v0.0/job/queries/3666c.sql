SELECT min(t.title) AS movie_title
FROM keyword AS k, movie_info AS mi, movie_keyword AS mk, title AS t
WHERE t.id = mi.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi.movie_id AND k.id = mk.keyword_id
AND k.phonetic_code < 'L5636' AND mi.note IN ('(138 episodes) (season 1-3 and season 5)', '(PCA #4009)', '(The European Independent Film Festival) (premiere)', '(certificate #34506)', '(certificate #39006)', 'Clair Soares', 'Michael Perez', 'Susan Boshcoff');