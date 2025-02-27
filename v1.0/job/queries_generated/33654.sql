WITH RECURSIVE MovieHierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS depth
    FROM
        aka_title mt
    WHERE
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    UNION ALL
    SELECT
        ml.linked_movie_id,
        mt.title,
        mt.production_year,
        mh.depth + 1
    FROM
        movie_link ml
    JOIN
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
    JOIN
        aka_title mt ON ml.linked_movie_id = mt.id
)

SELECT
    ak.name AS actor_name,
    COUNT(DISTINCT cc.movie_id) AS total_movies,
    STRING_AGG(DISTINCT mt.title, ', ') AS movie_titles,
    MAX(extract(year from mt.production_year)) AS last_movie_year,
    AVG(mv_info.info_type_id) FILTER (WHERE mv_info.info_type_id IS NOT NULL) AS avg_info_type,
    SUM(CASE WHEN ak.surname_pcode IS NULL THEN 1 ELSE 0 END) AS null_surname_count,
    RANK() OVER (PARTITION BY ak.id ORDER BY COUNT(DISTINCT cc.movie_id) DESC) AS actor_rank
FROM
    aka_name ak
LEFT JOIN
    cast_info cc ON ak.person_id = cc.person_id
LEFT JOIN
    aka_title mt ON cc.movie_id = mt.id
LEFT JOIN
    movie_info mv_info ON mt.id = mv_info.movie_id
LEFT JOIN
    MovieHierarchy mh ON mt.id = mh.movie_id
WHERE
    ak.name IS NOT NULL
GROUP BY
    ak.id, ak.name
HAVING
    COUNT(DISTINCT cc.movie_id) > 5
ORDER BY
    actor_rank,
    total_movies DESC
LIMIT 10;
