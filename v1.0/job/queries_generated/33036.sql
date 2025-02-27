WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        NULL::integer AS parent_movie_id,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.episode_of_id IS NULL

    UNION ALL

    SELECT 
        e.id AS movie_id,
        e.title,
        h.movie_id AS parent_movie_id,
        h.level + 1
    FROM 
        aka_title e
    JOIN 
        MovieHierarchy h ON e.episode_of_id = h.movie_id
),
RankedMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        COUNT(cc.id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY mh.level ORDER BY COUNT(cc.id) DESC) AS rn
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        cast_info cc ON mh.movie_id = cc.movie_id
    GROUP BY 
        mh.movie_id, mh.title, mh.level
),
TopCast AS (
    SELECT 
        ak.name,
        COUNT(*) AS appear_count,
        SUM(COALESCE(mc.company_id, 0)) AS affiliated_company_count
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    LEFT JOIN 
        movie_companies mc ON ci.movie_id = mc.movie_id
    GROUP BY 
        ak.name
)
SELECT 
    rm.title AS movie_title,
    rm.cast_count,
    tc.name AS actor_name,
    tc.appear_count,
    COALESCE(tc.affiliated_company_count, 0) AS affiliated_company_count,
    mh.level
FROM 
    RankedMovies rm
JOIN 
    TopCast tc ON rm.cast_count > 5 AND tc.appear_count > 3
JOIN 
    MovieHierarchy mh ON rm.movie_id = mh.movie_id
WHERE 
    mh.level <= 3 
ORDER BY 
    mh.level, rm.cast_count DESC, tc.appear_count DESC;
