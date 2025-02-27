WITH RECURSIVE movie_hierarchy AS (
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
        ml.linked_movie_id,
        mt.title,
        mt.production_year,
        mh.level + 1
    FROM
        movie_link ml
    JOIN
        aka_title mt ON ml.movie_id = mt.id
    JOIN
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    WHERE
        mh.level < 3  
)

SELECT
    mh.movie_id,
    mh.title,
    mh.production_year,
    COUNT(DISTINCT ci.person_id) AS total_cast,
    AVG(CASE WHEN ri.role IS NOT NULL THEN 1 ELSE 0 END) AS avg_has_role,
    STRING_AGG(DISTINCT ak.name, ', ') AS known_actors,
    SUM(CASE WHEN mi.info_type_id IS NOT NULL THEN 1 ELSE 0 END) AS info_count
FROM
    movie_hierarchy mh
LEFT JOIN
    cast_info ci ON mh.movie_id = ci.movie_id
LEFT JOIN
    role_type ri ON ci.role_id = ri.id
LEFT JOIN
    aka_name ak ON ci.person_id = ak.person_id
LEFT JOIN
    movie_info mi ON mh.movie_id = mi.movie_id
WHERE
    mh.production_year IS NOT NULL
GROUP BY
    mh.movie_id,
    mh.title,
    mh.production_year
ORDER BY
    mh.production_year DESC,
    total_cast DESC
LIMIT 100;