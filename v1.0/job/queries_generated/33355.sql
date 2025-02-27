WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS main_title,
        0 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title AS linked_title,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    WHERE 
        mh.level < 3 -- limit the depth of the hierarchy
),

actor_details AS (
    SELECT 
        ak.person_id,
        ak.name,
        ci.movie_id,
        ci.role_id,
        ROW_NUMBER() OVER (PARTITION BY ak.person_id ORDER BY ci.nr_order) AS role_position
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    WHERE 
        ak.name IS NOT NULL
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
    mh.main_title,
    mh.level,
    ad.name AS actor_name,
    COUNT(DISTINCT ad.movie_id) AS total_movies,
    COALESCE(mk.keywords, 'No keywords') AS keywords
FROM 
    movie_hierarchy mh
LEFT JOIN 
    actor_details ad ON mh.movie_id = ad.movie_id
LEFT JOIN 
    movie_keywords mk ON mh.movie_id = mk.movie_id
WHERE 
    ad.role_position = 1 -- Selecting the first role of each actor
GROUP BY 
    mh.main_title, mh.level, ad.name, mk.keywords
HAVING 
    COUNT(DISTINCT ad.movie_id) > 1 -- Only include actors with more than one movie
ORDER BY 
    mh.level, total_movies DESC;
