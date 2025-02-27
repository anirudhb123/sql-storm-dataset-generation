WITH RecursiveActorMovies AS (
    SELECT c.person_id,
           a.name AS actor_name,
           t.title,
           t.production_year,
           ROW_NUMBER() OVER (PARTITION BY c.person_id ORDER BY t.production_year DESC) AS rn
    FROM cast_info c
    JOIN aka_name a ON c.person_id = a.person_id
    JOIN aka_title t ON c.movie_id = t.movie_id
    WHERE t.production_year IS NOT NULL
),
MovieTitles AS (
    SELECT m.movie_id,
           m.title,
           COUNT(DISTINCT c.person_id) AS actor_count,
           MAX(m.production_year) AS latest_year
    FROM aka_title m
    LEFT JOIN cast_info c ON m.movie_id = c.movie_id
    GROUP BY m.movie_id, m.title
),
HighProfileActors AS (
    SELECT actor_name,
           COUNT(*) AS movie_count
    FROM RecursiveActorMovies
    WHERE rn <= 5
    GROUP BY actor_name
    HAVING COUNT(*) > 3
)
SELECT m.title AS movie_title,
       m.actor_count,
       COALESCE(h.movie_count, 0) AS high_profile_actor_count,
       CASE 
           WHEN m.actor_count > 10 THEN 'Ensemble Cast'
           WHEN m.actor_count <= 10 AND m.actor_count > 2 THEN 'Moderate Cast'
           ELSE 'Minimal Cast'
       END AS cast_category,
       t.production_year,
       CASE 
           WHEN t.production_year < 2000 THEN 'Classic'
           ELSE 'Modern'
       END AS movie_era
FROM MovieTitles m
LEFT JOIN HighProfileActors h ON m.actor_count = h.movie_count
JOIN aka_title t ON m.movie_id = t.id
WHERE t.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('movie', 'series'))
  AND m.actor_count IS NOT NULL
ORDER BY m.actor_count DESC, t.production_year ASC;
