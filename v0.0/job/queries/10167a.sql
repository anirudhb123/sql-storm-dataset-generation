SELECT min(t.title) AS movie_title
FROM keyword AS k, movie_info AS mi, movie_keyword AS mk, title AS t
WHERE t.id = mi.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi.movie_id AND k.id = mk.keyword_id
AND mi.note IN ('(Fuji Eterna Vivid 160T 8543, Eterna 500T 8573, Eterna 400T 8583, Reala 500D 8592)', '(PCA #16084)', '(certificate #34402)', '<michael.e.barrett@att.net>', 'K. Marie Walters', 'Kirk Brown', 'Peter Klassen') AND t.title > 'Schrecken ohne Ende';