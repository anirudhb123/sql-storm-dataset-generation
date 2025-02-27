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
        mt.production_year IS NOT NULL

    UNION ALL

    SELECT 
        ml.linked_movie_id,
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
    ak.name AS actor_name,
    mh.title AS movie_title,
    mh.production_year,
    kt.kind AS movie_kind,
    COALESCE(gt.group_count, 0) AS grouped_movie_count,
    COUNT(DISTINCT m.id) OVER(PARTITION BY ak.id) AS total_movies_acted,
    ROW_NUMBER() OVER (PARTITION BY ak.id ORDER BY mh.production_year DESC) AS movie_rank
FROM 
    aka_name ak
LEFT JOIN 
    cast_info ci ON ak.person_id = ci.person_id
LEFT JOIN 
    MovieHierarchy mh ON ci.movie_id = mh.movie_id
LEFT JOIN 
    kind_type kt ON mh.kind_id = kt.id
LEFT JOIN (
    SELECT 
        ak.id,
        COUNT(mh.movie_id) AS group_count
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    JOIN 
        MovieHierarchy mh ON ci.movie_id = mh.movie_id
    GROUP BY 
        ak.id
) gt ON ak.id = gt.id
WHERE 
    mh.production_year >= 2000
    AND mh.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('movie', 'feature'))
ORDER BY 
    ak.name, mh.production_year DESC
LIMIT 100;
