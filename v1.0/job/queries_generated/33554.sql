WITH RECURSIVE MovieHierarchy AS (
    SELECT
        m.id AS movie_id,
        t.title,
        m.production_year,
        0 AS level
    FROM
        aka_title AS t
    JOIN
        title AS m ON t.movie_id = m.id
    WHERE
        m.production_year BETWEEN 2000 AND 2020

    UNION ALL

    SELECT
        mh.movie_id,
        mh.title,
        mh.production_year,
        mh.level + 1
    FROM
        MovieHierarchy AS mh
    JOIN
        movie_link AS ml ON mh.movie_id = ml.movie_id
    WHERE
        mh.level < 5
)

SELECT
    mk.movie_id,
    COUNT(DISTINCT CASE WHEN mk.keyword IS NOT NULL THEN mk.keyword END) AS keyword_count,
    STRING_AGG(DISTINCT ak.name, ', ') AS actor_names,
    AVG(CASE WHEN COALESCE(m.production_year, 0) > 0 THEN m.production_year ELSE NULL END) AS avg_production_year
FROM
    MovieHierarchy AS mh
JOIN
    movie_keyword AS mk ON mh.movie_id = mk.movie_id
LEFT JOIN
    cast_info AS ci ON mh.movie_id = ci.movie_id
LEFT JOIN
    aka_name AS ak ON ci.person_id = ak.person_id
LEFT JOIN
    title AS m ON mh.movie_id = m.id
WHERE
    mk.keyword IS NOT NULL
GROUP BY
    mk.movie_id
ORDER BY
    keyword_count DESC, avg_production_year ASC
LIMIT 10;


