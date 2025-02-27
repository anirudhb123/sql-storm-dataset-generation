
WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        mt.episode_of_id,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.episode_of_id IS NULL  
    
    UNION ALL
    
    SELECT 
        mt.id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        mt.episode_of_id,
        mh.level + 1
    FROM 
        aka_title mt
    JOIN 
        movie_hierarchy mh ON mt.episode_of_id = mh.movie_id  
),
cast_details AS (
    SELECT 
        c.id AS cast_id,
        a.name AS actor_name,
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS role_order
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        aka_title mt ON c.movie_id = mt.movie_id
),
aggregated_data AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COUNT(cd.cast_id) AS total_cast,
        MAX(cd.role_order) AS max_role_order,
        STRING_AGG(cd.actor_name, ', ') AS actors_list
    FROM 
        movie_hierarchy mh
    LEFT JOIN 
        cast_details cd ON mh.movie_id = cd.movie_id
    GROUP BY 
        mh.movie_id, mh.title, mh.production_year
)
SELECT 
    ad.title,
    ad.production_year,
    ad.total_cast,
    ad.max_role_order,
    CASE 
        WHEN ad.max_role_order IS NULL THEN 'No cast information'
        ELSE ad.actors_list
    END AS actors_list,
    COALESCE(k.keyword, 'No keyword') AS keyword_info
FROM 
    aggregated_data ad
LEFT JOIN 
    movie_keyword mk ON ad.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    ad.production_year >= 2000  
ORDER BY 
    ad.production_year DESC, ad.total_cast DESC;
