WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS depth
    FROM 
        aka_title m
    WHERE 
        m.episode_of_id IS NULL
    
    UNION ALL
    
    SELECT 
        e.id AS movie_id,
        e.title,
        e.production_year,
        mh.depth + 1
    FROM 
        aka_title e
    JOIN 
        movie_hierarchy mh ON e.episode_of_id = mh.movie_id
),
cast_summary AS (
    SELECT 
        ci.movie_id,
        STRING_AGG(DISTINCT ak.name, ', ') AS actors,
        COUNT(DISTINCT ak.id) AS actor_count
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        ci.movie_id
),
movie_keywords AS (
    SELECT 
        mk.movie_id,
        COUNT(DISTINCT k.keyword) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
movies_with_info AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COALESCE(cs.actors, 'No actors') AS actors,
        cs.actor_count,
        COALESCE(mk.keyword_count, 0) AS keyword_count
    FROM 
        movie_hierarchy mh
    LEFT JOIN 
        cast_summary cs ON mh.movie_id = cs.movie_id
    LEFT JOIN 
        movie_keywords mk ON mh.movie_id = mk.movie_id
)
SELECT 
    mwi.title,
    mwi.production_year,
    mwi.actors,
    mwi.actor_count,
    mwi.keyword_count,
    CASE 
        WHEN mwi.actor_count = 0 THEN 'Unknown Actor Presence'
        WHEN mwi.keyword_count > 5 THEN 'Popular Film'
        ELSE 'Less Popular'
    END AS film_category,
    ROW_NUMBER() OVER (PARTITION BY mwi.production_year ORDER BY mwi.actor_count DESC) AS rank_within_year
FROM 
    movies_with_info mwi
WHERE 
    mwi.production_year >= 2000
ORDER BY 
    mwi.production_year DESC, 
    mwi.actor_count DESC;
