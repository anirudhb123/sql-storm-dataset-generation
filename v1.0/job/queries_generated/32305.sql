WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        movie_hierarchy mh
    JOIN 
        aka_title m ON m.episode_of_id = mh.movie_id
),
cast_with_roles AS (
    SELECT 
        c.movie_id,
        p.name AS actor_name,
        rt.role AS role_name,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS role_order
    FROM 
        cast_info c
    JOIN 
        aka_name p ON c.person_id = p.person_id
    JOIN 
        role_type rt ON c.role_id = rt.id
),
movie_details AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COALESCE(ARRAY_AGG(DISTINCT cwr.actor_name ORDER BY cwr.role_order), '{}') AS actors,
        COUNT(DISTINCT kw.keyword) AS keyword_count
    FROM 
        movie_hierarchy mh
    LEFT JOIN 
        cast_with_roles cwr ON mh.movie_id = cwr.movie_id
    LEFT JOIN 
        movie_keyword mk ON mh.movie_id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    GROUP BY 
        mh.movie_id, mh.title, mh.production_year
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.actors,
    md.keyword_count
FROM 
    movie_details md
WHERE 
    md.keyword_count > 2
AND 
    EXISTS (
        SELECT 1
        FROM movie_info mi
        WHERE 
            mi.movie_id = md.movie_id 
            AND mi.info LIKE '%Oscar%'
    )
ORDER BY 
    md.production_year DESC,
    md.title;

