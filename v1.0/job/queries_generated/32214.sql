WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000
      AND
        mt.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.depth + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    COUNT(DISTINCT ci.person_id) AS cast_count,
    STRING_AGG(DISTINCT ak.name, ', ') AS actor_names,
    MAX(CASE 
        WHEN ci.nr_order = 1 THEN ak.name 
        ELSE NULL 
    END) AS main_actor,
    SUM(CASE 
        WHEN ci.role_id IS NULL OR ci.role_id = 0 THEN 1 
        ELSE 0 
    END) AS additional_roles
FROM 
    movie_hierarchy mh
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
LEFT JOIN 
    aka_name ak ON ci.person_id = ak.person_id
GROUP BY 
    mh.movie_id, mh.title, mh.production_year
HAVING 
    COUNT(DISTINCT ci.person_id) > 5
ORDER BY 
    mh.production_year DESC,
    cast_count DESC;
