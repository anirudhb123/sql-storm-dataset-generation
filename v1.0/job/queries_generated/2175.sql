WITH recursive movie_series AS (
    SELECT t.id AS movie_id, t.title, t.production_year, t.season_nr, t.episode_nr,
           ROW_NUMBER() OVER (PARTITION BY t.episode_of_id ORDER BY t.season_nr, t.episode_nr) AS episode_order
    FROM aka_title t
    WHERE t.episode_of_id IS NOT NULL
), movie_keywords AS (
    SELECT mk.movie_id, STRING_AGG(k.keyword, ', ') AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
), cast_details AS (
    SELECT ci.movie_id, STRING_AGG(a.name, ', ') AS cast_names
    FROM cast_info ci
    JOIN aka_name a ON ci.person_id = a.person_id
    GROUP BY ci.movie_id
)
SELECT m.movie_id, m.title, COALESCE(ms.episode_order, 0) AS episode_order, m.production_year,
       COALESCE(mk.keywords, 'No Keywords') AS keywords, COALESCE(cd.cast_names, 'No Cast') AS cast_names
FROM aka_title m
LEFT JOIN movie_series ms ON m.id = ms.movie_id
LEFT JOIN movie_keywords mk ON m.id = mk.movie_id
LEFT JOIN cast_details cd ON m.id = cd.movie_id
WHERE m.production_year >= 2000
  AND (m.kind_id IN (SELECT kt.id FROM kind_type kt WHERE kt.kind = 'feature' OR kt.kind = 'movie'))
ORDER BY m.production_year DESC, m.title ASC
LIMIT 100;
