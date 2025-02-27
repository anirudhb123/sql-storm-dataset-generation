SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND cn.id < 226656 AND k.keyword IN ('aspen-colorado', 'broken-timepiece-as-clue', 'burnt-chicken', 'cauldron', 'ivory-statue', 'killing-wife', 'lung-transplant', 'ramrod', 'wind-turbine', 'year-490-bc') AND t.episode_nr IS NOT NULL AND t.season_nr < 6;