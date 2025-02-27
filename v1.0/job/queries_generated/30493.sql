WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        1 AS level
    FROM title m
    WHERE m.id IS NOT NULL

    UNION ALL

    SELECT 
        m.linked_movie_id AS movie_id,
        t.title,
        mh.level + 1
    FROM movie_link m
    JOIN title t ON m.linked_movie_id = t.id
    JOIN MovieHierarchy mh ON mh.movie_id = m.movie_id
),
MaxLevel AS (
    SELECT 
        MAX(level) AS max_level
    FROM MovieHierarchy
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        level
    FROM MovieHierarchy
    WHERE level = (SELECT max_level FROM MaxLevel)
),
CastASRole AS (
    SELECT 
        ci.movie_id,
        r.role AS role_name,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM cast_info ci
    JOIN role_type r ON ci.role_id = r.id
    GROUP BY ci.movie_id, r.role
),
MovieStats AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        COALESCE(ca.actor_count, 0) AS actor_count,
        (SELECT COUNT(DISTINCT mk.keyword) FROM movie_keyword mk WHERE mk.movie_id = t.id) AS keyword_count,
        COALESCE(ci.count_companies, 0) AS company_count
    FROM title t
    LEFT JOIN CastASRole ca ON t.id = ca.movie_id
    LEFT JOIN (
        SELECT 
            mc.movie_id,
            COUNT(DISTINCT mc.company_id) AS count_companies 
        FROM movie_companies mc
        GROUP BY mc.movie_id
    ) ci ON t.id = ci.movie_id
)

SELECT 
    ms.movie_id,
    ms.title,
    ms.actor_count,
    ms.keyword_count,
    ms.company_count,
    CASE 
        WHEN ms.actor_count > 20 THEN 'High'
        WHEN ms.actor_count BETWEEN 10 AND 20 THEN 'Moderate'
        ELSE 'Low'
    END AS popularity_category
FROM MovieStats ms
WHERE ms.company_count IS NOT NULL 
  AND ms.actor_count < (SELECT AVG(actor_count) FROM MovieStats WHERE actor_count IS NOT NULL)
ORDER BY ms.actor_count DESC, ms.title;
