WITH RECURSIVE MovieHierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM
        aka_title mt
    WHERE
        mt.production_year >= 2000
    
    UNION ALL
    
    SELECT
        ml.linked_movie_id AS movie_id,
        lt.title,
        lt.production_year,
        mh.level + 1 AS level
    FROM
        MovieHierarchy mh
    JOIN
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN
        aka_title lt ON ml.linked_movie_id = lt.id
)

SELECT
    ak.name AS actor_name,
    mt.title AS movie_title,
    mt.production_year AS movie_year,
    COUNT(DISTINCT kc.keyword) AS keyword_count,
    AVG(mk.production_year - ak.name_pcode_nf) AS avg_year_difference,
    STRING_AGG(DISTINCT ci.note, ', ') AS role_notes,
    ROW_NUMBER() OVER (PARTITION BY ak.name ORDER BY mt.production_year DESC) AS movie_rank
FROM
    cast_info ci
JOIN
    aka_name ak ON ci.person_id = ak.person_id
JOIN
    aka_title mt ON ci.movie_id = mt.id
LEFT JOIN
    movie_keyword mk ON mt.id = mk.movie_id
LEFT JOIN
    keyword kc ON mk.keyword_id = kc.id
WHERE
    ak.name IS NOT NULL
    AND mt.production_year IS NOT NULL
    AND (mt.production_year BETWEEN 2000 AND EXTRACT(YEAR FROM CURRENT_DATE))
GROUP BY
    ak.name, mt.title, mt.production_year
HAVING
    COUNT(DISTINCT kc.keyword) > 0
ORDER BY
    movie_rank, movie_year DESC;

