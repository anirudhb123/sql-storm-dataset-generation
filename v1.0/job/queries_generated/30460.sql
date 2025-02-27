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
    WHERE
        mh.level < 5
)

SELECT
    ak.name AS actor_name,
    at.title AS movie_title,
    at.production_year,
    COUNT(DISTINCT kc.keyword) AS num_keywords,
    AVG(CASE WHEN pi.info IS NULL THEN 0 ELSE LENGTH(pi.info) END) AS avg_info_length,
    ROW_NUMBER() OVER (PARTITION BY ak.person_id ORDER BY at.production_year DESC) AS movie_rank
FROM
    aka_name ak
JOIN
    cast_info ci ON ak.person_id = ci.person_id
JOIN
    aka_title at ON ci.movie_id = at.id
LEFT JOIN 
    movie_keyword mk ON at.id = mk.movie_id
LEFT JOIN 
    keyword kc ON mk.keyword_id = kc.id
LEFT JOIN 
    person_info pi ON ak.person_id = pi.person_id AND pi.info_type_id = (
        SELECT id FROM info_type WHERE info = 'Biography'
    )
JOIN 
    MovieHierarchy mh ON at.id = mh.movie_id
WHERE
    ak.md5sum IS NOT NULL
    AND ak.name IS NOT NULL
    AND mh.level <= 3
GROUP BY
    ak.name, at.title, at.production_year
HAVING
    COUNT(DISTINCT kc.keyword) > 0
ORDER BY
    avg_info_length DESC, movie_rank ASC;
