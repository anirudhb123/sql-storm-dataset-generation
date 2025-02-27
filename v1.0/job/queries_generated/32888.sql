WITH RECURSIVE MovieHierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        1 AS level
    FROM
        aka_title mt
    WHERE
        mt.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL

    SELECT
        ml.linked_movie_id AS movie_id,
        a.title AS movie_title,
        a.production_year,
        mh.level + 1
    FROM
        movie_link ml
    JOIN
        aka_title a ON ml.linked_movie_id = a.id
    JOIN
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT
    mh.movie_title,
    mh.production_year,
    COUNT(DISTINCT ci.person_id) AS total_cast,
    SUM(CASE WHEN ci.role_id IS NULL THEN 1 ELSE 0 END) AS unknown_role_count,
    STRING_AGG(DISTINCT ak.name, ', ') AS known_actors,
    AVG(mv.info_length) AS average_info_length,
    ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY mh.movie_title) AS rank_within_year
FROM
    MovieHierarchy mh
LEFT JOIN
    cast_info ci ON mh.movie_id = ci.movie_id
LEFT JOIN
    aka_name ak ON ci.person_id = ak.person_id
LEFT JOIN (
    SELECT
        movie_id,
        LENGTH(info) AS info_length
    FROM
        movie_info
    WHERE
        info IS NOT NULL
) mv ON mv.movie_id = mh.movie_id
GROUP BY
    mh.movie_id, mh.movie_title, mh.production_year
HAVING
    COUNT(DISTINCT ci.person_id) > 5
ORDER BY
    mh.production_year DESC, rank_within_year;

