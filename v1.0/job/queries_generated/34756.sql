WITH RECURSIVE MovieHierarchy AS (
    -- Recursive CTE to get a hierarchy of movies and their links
    SELECT m.id AS movie_id, m.title, 1 AS level
    FROM aka_title m
    WHERE m.production_year >= 2000  -- Start with movies from 2000 onwards

    UNION ALL

    SELECT ml.linked_movie_id, mt.title, mh.level + 1
    FROM movie_link ml
    JOIN MovieHierarchy mh ON ml.movie_id = mh.movie_id
    JOIN aka_title mt ON ml.linked_movie_id = mt.id
),
TopActors AS (
    -- CTE to get top 5 actors by number of roles in movies
    SELECT ka.name, COUNT(ci.id) AS role_count
    FROM cast_info ci
    JOIN aka_name ka ON ci.person_id = ka.person_id
    GROUP BY ka.name
    ORDER BY role_count DESC
    LIMIT 5
),
MovieStatistics AS (
    -- CTE to calculate various statistics for movies
    SELECT 
        at.title,
        COUNT(DISTINCT cc.subject_id) AS total_cast,
        COUNT(DISTINCT mc.company_id) AS total_companies,
        SUM(CASE WHEN ki.keyword IS NOT NULL THEN 1 ELSE 0 END) AS keyword_count
    FROM aka_title at
    LEFT JOIN complete_cast cc ON at.id = cc.movie_id
    LEFT JOIN movie_companies mc ON at.id = mc.movie_id
    LEFT JOIN movie_keyword mk ON at.id = mk.movie_id
    LEFT JOIN keyword ki ON mk.keyword_id = ki.id
    WHERE at.production_year BETWEEN 2000 AND 2020
    GROUP BY at.title
)
-- Main query combining all CTEs
SELECT 
    mh.movie_id,
    mh.title AS movie_title,
    mh.level,
    ms.total_cast,
    ms.total_companies,
    ms.keyword_count,
    ta.name AS top_actor,
    ta.role_count,
    COALESCE(ta.role_count, 0) AS actor_role_count
FROM MovieHierarchy mh
JOIN MovieStatistics ms ON mh.title = ms.movie_title
LEFT JOIN TopActors ta ON ta.role_count IN (
    SELECT role_count FROM TopActors ORDER BY role_count DESC
)
WHERE mh.level = 2  -- Filter to show only movies that are at level 2 in the hierarchy
ORDER BY mh.title, actor_role_count DESC;
