
WITH RECURSIVE movie_hierarchy AS (
    SELECT m.id AS movie_id, m.title, 1 AS level
    FROM aka_title m
    WHERE m.production_year >= 2000

    UNION ALL

    SELECT m.id, m.title, mh.level + 1
    FROM movie_link ml
    JOIN movie_hierarchy mh ON ml.movie_id = mh.movie_id
    JOIN aka_title m ON ml.linked_movie_id = m.id
    WHERE mh.level < 3
),
cast_stats AS (
    SELECT 
        c.movie_id,
        COUNT(*) AS total_cast,
        COUNT(CASE WHEN r.role = 'actor' THEN 1 END) AS actor_count,
        COUNT(CASE WHEN r.role = 'director' THEN 1 END) AS director_count
    FROM cast_info c
    JOIN role_type r ON c.role_id = r.id
    GROUP BY c.movie_id
),
movie_keywords AS (
    SELECT 
        mk.movie_id,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
),
detailed_movie_info AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        COALESCE(c.total_cast, 0) AS total_cast,
        COALESCE(c.actor_count, 0) AS actor_count,
        COALESCE(c.director_count, 0) AS director_count,
        COALESCE(mk.keywords, 'None') AS keywords,
        mh.level AS hierarchy_level
    FROM aka_title m
    LEFT JOIN cast_stats c ON m.id = c.movie_id
    LEFT JOIN movie_keywords mk ON m.id = mk.movie_id
    LEFT JOIN movie_hierarchy mh ON m.id = mh.movie_id
    WHERE m.production_year >= 2000
),
final_output AS (
    SELECT 
        d.title,
        d.total_cast,
        d.actor_count,
        d.director_count,
        d.keywords,
        d.hierarchy_level,
        ROW_NUMBER() OVER (PARTITION BY d.hierarchy_level ORDER BY d.actor_count DESC) AS rn
    FROM detailed_movie_info d
    WHERE d.hierarchy_level IS NOT NULL
)
SELECT 
    f.title,
    f.total_cast,
    f.actor_count,
    f.director_count,
    f.keywords,
    f.hierarchy_level
FROM final_output f
WHERE f.rn <= 10
ORDER BY f.hierarchy_level, f.actor_count DESC;
