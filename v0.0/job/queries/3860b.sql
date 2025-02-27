SELECT min(lt.link) AS link_type, min(t1.title) AS first_movie, min(t2.title) AS second_movie
FROM keyword AS k, link_type AS lt, movie_keyword AS mk, movie_link AS ml, title AS t1, title AS t2
WHERE mk.keyword_id = k.id AND t1.id = mk.movie_id AND ml.movie_id = t1.id AND ml.linked_movie_id = t2.id AND lt.id = ml.link_type_id AND mk.movie_id = t1.id
AND t2.series_years IN ('1962-1993', '1965-2003', '1967-1985', '1974-1978', '1978-1995', '1980-1981', '1997-2007', '1998-1999');