SELECT min(t.title) AS movie_title
FROM keyword AS k, movie_info AS mi, movie_keyword AS mk, title AS t
WHERE t.id = mi.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi.movie_id AND k.id = mk.keyword_id
AND t.episode_nr IS NOT NULL AND mi.info > 'CHAR: The Genovian motto written in Latin "Totus Corpus Laborat" has a grammatical error in it. The motto should actually be "Totum Corpus Laborat". Totus is a masculine form of the adjective, but the noun corpus is neuter.' AND k.keyword LIKE '%growing%';