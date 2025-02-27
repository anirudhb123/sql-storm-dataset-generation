WITH RECURSIVE movie_hierarchy AS (
    SELECT mt.id AS movie_id, 
           mt.title, 
           0 AS level
    FROM aka_title mt
    WHERE mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')  -- Only movies
    UNION ALL
    SELECT mt.id AS movie_id,
           mt.title,
           mh.level + 1
    FROM movie_link ml
    JOIN movie_hierarchy mh ON mh.movie_id = ml.movie_id
    JOIN aka_title mt ON mt.id = ml.linked_movie_id
    WHERE mh.level < 5  -- Limit recursion depth to prevent too many levels
), 
cast_aggregates AS (
    SELECT ci.movie_id,
           COUNT(DISTINCT ci.person_id) AS actor_count,
           STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM cast_info ci
    LEFT JOIN movie_keyword mk ON ci.movie_id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY ci.movie_id
), 
movie_info_grouped AS (
    SELECT mi.movie_id, 
           STRING_AGG(DISTINCT mi.info, '; ') AS full_info
    FROM movie_info mi
    WHERE mi.info IS NOT NULL
    GROUP BY mi.movie_id
),
avg_cast_role AS (
    SELECT ci.movie_id,
           AVG(CASE WHEN ct.kind ILIKE 'lead%' THEN ci.nr_order ELSE NULL END) AS avg_lead_role
    FROM cast_info ci
    JOIN comp_cast_type ct ON ci.person_role_id = ct.id
    GROUP BY ci.movie_id
),
movie_ranking AS (
    SELECT mh.movie_id,
           mh.title,
           ca.actor_count,
           mig.full_info,
           acr.avg_lead_role,
           ROW_NUMBER() OVER (ORDER BY ca.actor_count DESC, acr.avg_lead_role DESC) AS movie_rank
    FROM movie_hierarchy mh
    LEFT JOIN cast_aggregates ca ON mh.movie_id = ca.movie_id
    LEFT JOIN movie_info_grouped mig ON mh.movie_id = mig.movie_id
    LEFT JOIN avg_cast_role acr ON mh.movie_id = acr.movie_id
)
SELECT *,
       CASE 
           WHEN actor_count IS NULL THEN 'No Cast Information'
           ELSE 'Cast present'
       END AS cast_info_status,
       CASE 
           WHEN full_info IS NULL THEN 'No Movie Info'
           ELSE 'Movie Info Available'
       END AS info_status
FROM movie_ranking
WHERE (actor_count > 5 OR avg_lead_role IS NOT NULL)  -- Filtering based on actor count or lead role average
  AND movie_rank <= 10  -- Top 10 movies
ORDER BY movie_rank, title;
