SELECT min(t.title) AS movie_title
FROM keyword AS k, movie_info AS mi, movie_keyword AS mk, title AS t
WHERE t.id = mi.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi.movie_id AND k.id = mk.keyword_id
AND k.keyword IN ('dirty-politics', 'eating-a-contract', 'electronic-music-score-in-style-of-orchestral-music-score', 'mandatory-sentencing', 'rabin-assassination', 'reefer', 'reference-to-tevye-the-milkman', 'river-havel', 'scrap', 'taking-a-bath') AND t.season_nr IS NOT NULL AND k.phonetic_code IS NOT NULL AND t.episode_of_id > 13649;