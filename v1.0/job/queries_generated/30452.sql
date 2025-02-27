WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        at.kind_id,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    mh.level,
    COUNT(DISTINCT ci.person_id) AS actor_count,
    AVG(CASE 
        WHEN ci.nr_order IS NOT NULL THEN ci.nr_order 
        ELSE 0 
    END) AS avg_order,
    STRING_AGG(CASE 
        WHEN ca.name IS NOT NULL THEN ca.name 
        ELSE 'Unknown' 
    END, ', ') AS actors
FROM 
    MovieHierarchy mh
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.id
LEFT JOIN 
    aka_name ca ON ci.person_id = ca.person_id
WHERE 
    mh.production_year IS NOT NULL
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, mh.level
HAVING 
    COUNT(DISTINCT ci.person_id) > 3 AND 
    AVG(COALESCE(ci.nr_order, 0)) >= 2
ORDER BY 
    mh.production_year DESC, mh.level, actor_count DESC;
