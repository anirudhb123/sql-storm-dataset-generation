SELECT min(k.keyword) AS movie_keyword, min(n.name) AS actor_name, min(t.title) AS hero_movie
FROM cast_info AS ci, keyword AS k, movie_keyword AS mk, name AS n, title AS t
WHERE k.id = mk.keyword_id AND t.id = mk.movie_id AND t.id = ci.movie_id AND ci.movie_id = mk.movie_id AND n.id = ci.person_id
AND t.series_years LIKE '%2012%' AND ci.id < 15402373 AND k.phonetic_code > 'E31' AND k.keyword IN ('ben-gay', 'bequeath', 'chlorohydrate', 'fight-with-self', 'melba-toast', 'missile-launcher', 'peer-evaluation', 'search-party', 'spaceflight-test', 'wedding-planning');