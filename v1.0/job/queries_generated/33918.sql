WITH RECURSIVE MovieHierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        0 AS level
    FROM
        aka_title mt
    WHERE
        mt.production_year >= 2000
    
    UNION ALL
    
    SELECT
        ml.linked_movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
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
    mt.title AS movie_title,
    mt.production_year,
    mh.level AS movie_level,
    COUNT(DISTINCT kc.keyword) AS keyword_count,
    AVG(CASE WHEN pi.info_type_id IS NOT NULL THEN 1 ELSE 0 END) AS has_person_info,
    ROW_NUMBER() OVER (PARTITION BY ak.name ORDER BY mt.production_year DESC) AS rn
FROM
    cast_info ci
JOIN
    aka_name ak ON ci.person_id = ak.person_id
JOIN
    MovieHierarchy mh ON ci.movie_id = mh.movie_id
JOIN
    movie_keyword mk ON mh.movie_id = mk.movie_id
JOIN
    keyword kc ON mk.keyword_id = kc.id
LEFT JOIN
    person_info pi ON ci.person_id = pi.person_id AND pi.info_type_id = (SELECT id FROM info_type WHERE info = 'dob')
WHERE
    mh.production_year IS NOT NULL
    AND ak.name IS NOT NULL
    AND kc.keyword IS NOT NULL
GROUP BY
    ak.name, mt.title, mt.production_year, mh.level
HAVING
    COUNT(DISTINCT kc.keyword) > 5
ORDER BY
    ak.name, mt.production_year DESC;

