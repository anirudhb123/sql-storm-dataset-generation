
WITH movie_cast AS (
    SELECT c.movie_id, a.name AS actor_name, 
           ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS actor_order
    FROM cast_info c
    JOIN aka_name a ON c.person_id = a.person_id
    WHERE a.name IS NOT NULL
),
explicit_movie_info AS (
    SELECT m.movie_id, m.title, 
           COALESCE(mi.info, 'No Info Available') AS movie_info, 
           m.production_year, 
           COUNT(k.keyword) AS keyword_count
    FROM aka_title m
    LEFT JOIN movie_info mi ON m.id = mi.movie_id 
    LEFT JOIN movie_keyword mk ON m.id = mk.movie_id 
    LEFT JOIN keyword k ON mk.keyword_id = k.id 
    GROUP BY m.movie_id, m.title, mi.info, m.production_year
),
cast_summary AS (
    SELECT mc.movie_id, 
           LISTAGG(mc.actor_name, ', ') WITHIN GROUP (ORDER BY mc.actor_order) AS actors_list,
           MAX(mc.actor_order) AS total_actors
    FROM movie_cast mc
    GROUP BY mc.movie_id
)
SELECT em.movie_id, em.title, em.movie_info, em.production_year,
       cs.actors_list, cs.total_actors,
       CASE 
           WHEN em.production_year IS NULL THEN 'Unknown Year'
           WHEN em.production_year < 1980 THEN 'Classic'
           WHEN em.production_year BETWEEN 1980 AND 1999 THEN 'Modern Classic'
           ELSE 'Contemporary'
       END AS year_category,
       (SELECT COUNT(DISTINCT c.id)
        FROM complete_cast c
        WHERE c.movie_id = em.movie_id) AS complete_cast_count
FROM explicit_movie_info em
LEFT JOIN cast_summary cs ON em.movie_id = cs.movie_id
WHERE (em.keyword_count > 2 OR cs.total_actors > 5)
  AND (em.production_year IS NOT NULL OR cs.actors_list IS NOT NULL)
ORDER BY em.production_year DESC, em.title
OFFSET 5 ROWS 
LIMIT 10;
