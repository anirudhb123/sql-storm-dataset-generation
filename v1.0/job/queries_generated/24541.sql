WITH RECURSIVE movie_cte AS (
    SELECT mt.id AS movie_id, mt.title, mt.production_year, 0 AS level
    FROM aka_title mt
    WHERE mt.production_year > 2000
    UNION ALL
    SELECT mt.id AS movie_id, mt.title, mt.production_year, cte.level + 1
    FROM movie_link ml
    JOIN movie_cte cte ON ml.movie_id = cte.movie_id
    JOIN aka_title mt ON ml.linked_movie_id = mt.id
    WHERE cte.level < 3
),

actor_role_agg AS (
    SELECT c.person_id, r.role, COUNT(c.id) AS movie_count
    FROM cast_info c
    JOIN role_type r ON c.role_id = r.id
    GROUP BY c.person_id, r.role
    HAVING COUNT(c.id) > 2
),

actor_name AS (
    SELECT ka.id, ka.name
    FROM aka_name ka
    WHERE EXISTS (
        SELECT 1
        FROM actor_role_agg agg
        WHERE agg.person_id = ka.person_id
        AND agg.movie_count > 2
    )
),

unique_keywords AS (
    SELECT DISTINCT k.keyword
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    WHERE k.keyword IS NOT NULL
)

SELECT 
    a.name AS actor_name,
    COUNT(DISTINCT m.movie_id) AS total_movies,
    ARRAY_AGG(DISTINCT kw.keyword) AS keywords_used,
    AVG(m.production_year) AS avg_prod_year,
    CASE 
        WHEN COUNT(DISTINCT m.movie_id) < 5 THEN 'Novice'
        WHEN COUNT(DISTINCT m.movie_id) BETWEEN 5 AND 15 THEN 'Intermediate'
        ELSE 'Veteran'
    END AS actor_experience_level
FROM actor_name a
FULL OUTER JOIN (
    SELECT DISTINCT movie_id, title, production_year
    FROM movie_cte
    WHERE title IS NOT NULL
) m ON TRUE
LEFT JOIN movie_keyword mk ON mk.movie_id = m.movie_id
LEFT JOIN unique_keywords kw ON mk.keyword_id = (
    SELECT uk.id
    FROM keyword uk
    WHERE uk.keyword LIKE '%' || m.title || '%'
    LIMIT 1
)
WHERE a.name IS NOT NULL
GROUP BY a.name
ORDER BY actor_experience_level DESC, total_movies DESC;
