
WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        1 AS level,
        mt.production_year,
        NULL AS parent_id
    FROM 
        aka_title mt
    WHERE 
        mt.episode_of_id IS NULL

    UNION ALL

    SELECT 
        et.id,
        et.title,
        mh.level + 1,
        et.production_year,
        mh.movie_id
    FROM 
        aka_title et
    INNER JOIN 
        movie_hierarchy mh ON et.episode_of_id = mh.movie_id
),
cast_roles AS (
    SELECT 
        ci.movie_id,
        rt.role,
        COUNT(DISTINCT ci.person_id) AS role_count
    FROM 
        cast_info ci
    INNER JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        ci.movie_id, rt.role
),
movie_keywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    INNER JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
top_movies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COALESCE(cr.role_count, 0) AS actor_count,
        COALESCE(mk.keywords, '') AS keywords
    FROM 
        movie_hierarchy mh
    LEFT JOIN 
        cast_roles cr ON mh.movie_id = cr.movie_id
    LEFT JOIN 
        movie_keywords mk ON mh.movie_id = mk.movie_id
    WHERE 
        mh.level = 1 AND 
        mh.production_year BETWEEN 2000 AND 2022
)
SELECT 
    title,
    production_year,
    actor_count,
    keywords AS keyword_list
FROM 
    top_movies
WHERE 
    actor_count >= 3
ORDER BY 
    production_year DESC, actor_count DESC;
