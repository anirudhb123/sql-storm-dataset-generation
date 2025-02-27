WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        NULL AS parent_id
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL
    
    UNION ALL
    
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.movie_id AS parent_id
    FROM 
        aka_title m
    JOIN 
        movie_link ml ON m.id = ml.linked_movie_id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
),
movie_cast AS (
    SELECT 
        mm.movie_id,
        a.name AS actor_name,
        c.nr_order,
        ROW_NUMBER() OVER (PARTITION BY mm.movie_id ORDER BY c.nr_order) AS actor_rank
    FROM 
        cast_info c
    JOIN 
        aka_name a ON a.person_id = c.person_id
    JOIN 
        aka_title mm ON mm.id = c.movie_id
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
    mk.keywords,
    mc.actor_name,
    mc.actor_rank
FROM 
    movie_hierarchy mh
LEFT JOIN 
    movie_keywords mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    movie_cast mc ON mh.movie_id = mc.movie_id
WHERE 
    mh.production_year >= 2000 
    AND (mc.actor_name IS NOT NULL OR mk.keywords IS NOT NULL)
ORDER BY 
    mh.production_year DESC, 
    mc.actor_rank
FETCH FIRST 100 ROWS ONLY;
