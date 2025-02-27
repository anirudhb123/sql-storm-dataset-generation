WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level,
        mt.episode_of_id
    FROM 
        aka_title mt
    WHERE 
        mt.episode_of_id IS NULL
    
    UNION ALL
    
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mh.level + 1,
        mt.episode_of_id
    FROM 
        aka_title mt
    INNER JOIN 
        movie_hierarchy mh ON mt.episode_of_id = mh.movie_id
),

cast_details AS (
    SELECT
        ci.movie_id,
        ac.name AS actor_name,
        rt.role AS role_type,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS actor_rank
    FROM 
        cast_info ci
    JOIN 
        aka_name ac ON ci.person_id = ac.person_id
    JOIN 
        role_type rt ON ci.role_id = rt.id
),

movie_keywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)

SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    cd.actor_name,
    cd.role_type,
    cd.actor_rank,
    COALESCE(mk.keywords, 'No keywords') AS keywords,
    CASE 
        WHEN CAST(mh.production_year AS INTEGER) < 2000 THEN 'Classic'
        WHEN CAST(mh.production_year AS INTEGER) BETWEEN 2000 AND 2010 THEN 'Modern'
        ELSE 'Recent'
    END AS era,
    COUNT(cd.actor_name) OVER (PARTITION BY mh.movie_id) AS total_actors
FROM 
    movie_hierarchy mh
LEFT JOIN 
    cast_details cd ON mh.movie_id = cd.movie_id
LEFT JOIN 
    movie_keywords mk ON mh.movie_id = mk.movie_id
ORDER BY 
    mh.production_year DESC, mh.title, cd.actor_rank;
