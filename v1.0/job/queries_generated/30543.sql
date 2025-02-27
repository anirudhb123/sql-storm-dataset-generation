WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year = 2023

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
),

movie_cast AS (
    SELECT 
        ci.movie_id,
        ak.name AS actor_name,
        ak.id AS actor_id,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS actor_order
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
),

movie_info_filtered AS (
    SELECT 
        mi.movie_id,
        STRING_AGG(mi.info, ', ') AS info_details
    FROM 
        movie_info mi
    WHERE 
        mi.info IS NOT NULL AND
        mi.note IS NOT NULL
    GROUP BY 
        mi.movie_id
)

SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    COALESCE(mf.info_details, 'No Info') AS details,
    GROUP_CONCAT(mc.actor_name ORDER BY mc.actor_order SEPARATOR ', ') AS cast
FROM 
    movie_hierarchy mh
LEFT JOIN 
    movie_info_filtered mf ON mh.movie_id = mf.movie_id
LEFT JOIN 
    movie_cast mc ON mh.movie_id = mc.movie_id
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, mf.info_details
HAVING 
    mh.production_year IN (2022, 2023)
ORDER BY 
    mh.production_year DESC, mh.title;
