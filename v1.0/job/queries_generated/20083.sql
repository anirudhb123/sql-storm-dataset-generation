WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id, 
        mt.title AS movie_title, 
        mt.production_year, 
        0 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id IS NOT NULL

    UNION ALL

    SELECT 
        ml.linked_movie_id, 
        mt.title, 
        mt.production_year, 
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.id
)

SELECT
    ak.name AS actor_name,
    mt.movie_title,
    mh.level,
    COALESCE(CAST(ROUND(AVG(mv.production_year - mt.production_year + 0.0), 2) AS NUMERIC), 0) AS average_year_difference,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
    SUM(CASE 
        WHEN ci.note IS NULL THEN 1 
        ELSE 0 
    END) AS null_note_count,
    COUNT(DISTINCT ci.role_id) AS unique_roles,

    RANK() OVER (PARTITION BY ak.person_id ORDER BY AVG(mv.production_year) DESC) AS role_rank

FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    MovieHierarchy mh ON ci.movie_id = mh.movie_id
JOIN 
    aka_title mt ON mh.movie_id = mt.id
JOIN 
    movie_keyword mk ON mt.id = mk.movie_id
JOIN 
    keyword kw ON mk.keyword_id = kw.id
LEFT JOIN 
    aka_title mv ON mv.id = ci.movie_id

WHERE 
    ak.name IS NOT NULL 
    AND mh.production_year > 2000 
    AND (mt.production_year IS NULL OR mt.production_year > 1990 OR ak.name NOT LIKE '%*%')

GROUP BY 
    ak.person_id, mt.movie_title, mh.level
ORDER BY 
    average_year_difference DESC, ak.actor_name;
