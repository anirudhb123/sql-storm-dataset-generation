WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        0 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year < 2000 -- Base case for recursion, movies before the year 2000
    
    UNION ALL
    
    SELECT 
        mt.id,
        mt.title,
        mt.production_year,
        mh.level + 1
    FROM 
        movie_hierarchy mh
    JOIN 
        aka_title mt ON mh.movie_id = mt.episode_of_id -- Recursive step to find episodes
    WHERE
        mh.level < 3 -- Limit the recursion depth
),
movie_cast_info AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        r.role AS actor_role,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY a.name) AS actor_order
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
),
movie_keywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords -- Aggregating keywords into a single string
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
movie_details AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COALESCE(mki.actor_name, 'No Cast') AS lead_actor,
        COALESCE(mki.actor_role, 'Unknown Role') AS lead_actor_role,
        mk.keywords
    FROM 
        movie_hierarchy mh
    LEFT JOIN 
        (SELECT 
            movie_id, 
            MIN(actor_order) AS min_order
        FROM 
            movie_cast_info 
        GROUP BY 
            movie_id) AS mc ON mh.movie_id = mc.movie_id
    LEFT JOIN 
        movie_cast_info mki ON mc.movie_id = mki.movie_id AND mki.actor_order = 1 -- Get top actor
    LEFT JOIN 
        movie_keywords mk ON mh.movie_id = mk.movie_id
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.lead_actor,
    md.lead_actor_role,
    md.keywords
FROM 
    movie_details md
WHERE 
    md.production_year IS NOT NULL -- Ensuring valid production year
    AND (md.keywords IS NOT NULL OR md.lead_actor IS NOT NULL) -- At least one valid detail
ORDER BY 
    md.production_year DESC, 
    md.title ASC
LIMIT 50; -- Limit results for performance benchmarking
