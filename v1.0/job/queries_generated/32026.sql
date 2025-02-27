WITH RECURSIVE MovieHierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        1 AS level,
        mt.production_year,
        mt.kind_id,
        NULL AS parent_movie_id
    FROM 
        aka_title mt
    WHERE
        mt.production_year IS NOT NULL

    UNION ALL

    SELECT
        ml.linked_movie_id AS movie_id,
        m.title,
        mh.level + 1 AS level,
        m.production_year,
        m.kind_id,
        mh.movie_id AS parent_movie_id
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
)
SELECT
    mh.title AS movie_title,
    mh.production_year,
    COUNT(DISTINCT ci.person_id) AS num_cast,
    STRING_AGG(DISTINCT ak.name, ', ') AS actor_names,
    MAX(CASE WHEN ci.role_id IS NOT NULL THEN 'Available' ELSE 'Unavailable' END) AS role_availability,
    AVG(CASE WHEN mt.kind_id IN (1, 2) THEN 1 ELSE NULL END) OVER (PARTITION BY mh.production_year) AS avg_movie_type,
    COUNT(DISTINCT CASE WHEN mi.info_type_id = 1 THEN mi.info END) AS num_info_types
FROM
    MovieHierarchy mh
LEFT JOIN
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON ci.movie_id = mh.movie_id
LEFT JOIN 
    aka_name ak ON ci.person_id = ak.person_id
LEFT JOIN 
    movie_info mi ON mh.movie_id = mi.movie_id
WHERE
    mh.kind_id IN (1, 2) -- Assuming 1 and 2 are relevant movie types
GROUP BY
    mh.movie_id, mh.title, mh.production_year
ORDER BY
    mh.production_year DESC, num_cast DESC
LIMIT 10;
