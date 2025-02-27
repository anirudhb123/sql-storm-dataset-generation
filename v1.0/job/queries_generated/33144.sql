WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        m.kind_id,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.episode_of_id IS NULL  -- Base case: no episodes of a series
    
    UNION ALL
    
    SELECT 
        e.id AS movie_id,
        e.title AS movie_title,
        e.production_year,
        e.kind_id,
        mh.level + 1
    FROM 
        aka_title e
    INNER JOIN 
        movie_hierarchy mh ON e.episode_of_id = mh.movie_id  -- Recursive case: join on episodes
),
cast_with_roles AS (
    SELECT 
        ci.movie_id,
        ka.name AS actor_name,
        rt.role AS role_name,
        COUNT(*) OVER (PARTITION BY ci.movie_id) AS total_cast,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS actor_rank
    FROM 
        cast_info ci
    INNER JOIN 
        aka_name ka ON ci.person_id = ka.person_id
    LEFT JOIN 
        role_type rt ON ci.role_id = rt.id
),
movie_keywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(mk.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    INNER JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
movies_with_cast AS (
    SELECT 
        mh.movie_id,
        mh.movie_title,
        mh.production_year,
        cwr.actor_name,
        cwr.role_name,
        cwr.total_cast,
        cwr.actor_rank,
        mk.keywords
    FROM 
        movie_hierarchy mh
    LEFT JOIN 
        cast_with_roles cwr ON mh.movie_id = cwr.movie_id
    LEFT JOIN 
        movie_keywords mk ON mh.movie_id = mk.movie_id
)
SELECT 
    mwc.movie_id,
    mwc.movie_title,
    mwc.production_year,
    mwc.actor_name,
    mwc.role_name,
    mwc.total_cast,
    mwc.actor_rank,
    mwc.keywords
FROM 
    movies_with_cast mwc
WHERE 
    mwc.production_year BETWEEN 2000 AND 2020
    AND (mwc.role_name IS NOT NULL OR mwc.keywords IS NOT NULL)  -- Including those with roles or keywords
ORDER BY 
    mwc.production_year DESC, 
    mwc.actor_rank;
