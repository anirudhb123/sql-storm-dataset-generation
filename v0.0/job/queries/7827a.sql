SELECT min(k.keyword) AS movie_keyword, min(n.name) AS actor_name, min(t.title) AS hero_movie
FROM cast_info AS ci, keyword AS k, movie_keyword AS mk, name AS n, title AS t
WHERE k.id = mk.keyword_id AND t.id = mk.movie_id AND t.id = ci.movie_id AND ci.movie_id = mk.movie_id AND n.id = ci.person_id
AND n.name_pcode_cf IN ('B525', 'I6535', 'S5126', 'W2326', 'W4565', 'Z626') AND n.name > 'Kanitkar, Rishikesh' AND t.md5sum < 'e04a4a058668beb60efad58b131731e8';