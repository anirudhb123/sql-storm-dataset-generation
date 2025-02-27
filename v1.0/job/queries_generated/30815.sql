WITH RECURSIVE MovieHierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM
        aka_title mt
    WHERE
        mt.production_year >= 2000  -- Base case: movies produced after 2000

    UNION ALL

    SELECT
        ml.linked_movie_id,
        mt.title,
        mt.production_year,
        mh.level + 1 AS level
    FROM
        MovieHierarchy mh
    JOIN
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN
        aka_title mt ON ml.linked_movie_id = mt.id
)
SELECT
    ch.name AS character_name,
    ak.name AS actor_name,
    mh.title AS movie_title,
    mh.production_year,
    COUNT(DISTINCT mc.company_id) AS company_count,
    AVG(CASE WHEN mi.info_type_id = 1 THEN NULLIF(LENGTH(mi.info), 0) END) AS avg_movie_info_length,
    ROW_NUMBER() OVER (PARTITION BY ak.name ORDER BY mh.production_year DESC) AS rn
FROM
    MovieHierarchy mh
JOIN
    complete_cast cc ON mh.movie_id = cc.movie_id
JOIN
    cast_info ci ON cc.subject_id = ci.id
JOIN
    aka_name ak ON ci.person_id = ak.person_id
LEFT JOIN
    movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN
    movie_info mi ON mh.movie_id = mi.movie_id
LEFT JOIN
    char_name ch ON ci.role_id = ch.id
WHERE
    ak.name IS NOT NULL
    AND mh.production_year IS NOT NULL
GROUP BY
    ch.name, ak.name, mh.title, mh.production_year
HAVING
    COUNT(DISTINCT mc.company_id) > 1  -- Only consider movies having more than one company
ORDER BY
    mh.production_year DESC, ak.name;
