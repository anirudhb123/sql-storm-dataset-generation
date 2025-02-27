WITH RECURSIVE movie_hierarchy AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        0 AS level
    FROM
        aka_title m
    WHERE
        m.production_year IS NOT NULL

    UNION ALL

    SELECT
        p.linked_movie_id,
        m.title,
        m.production_year,
        mh.level + 1 AS level
    FROM
        movie_link p
    JOIN
        aka_title m ON m.id = p.linked_movie_id
    JOIN
        movie_hierarchy mh ON mh.movie_id = p.movie_id
)
SELECT
    mh.title AS movie_title,
    mh.production_year,
    COUNT(DISTINCT ci.person_id) AS actor_count,
    STRING_AGG(DISTINCT ak.name, ', ') AS actors,
    SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS has_notes,
    ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
FROM
    movie_hierarchy mh
LEFT JOIN
    complete_cast cc ON cc.movie_id = mh.movie_id
LEFT JOIN
    cast_info ci ON ci.movie_id = cc.movie_id
LEFT JOIN
    aka_name ak ON ak.person_id = ci.person_id
WHERE
    mh.level < 2
GROUP BY
    mh.movie_id, mh.title, mh.production_year
HAVING
    COUNT(DISTINCT ci.person_id) > 0
ORDER BY
    mh.production_year DESC, actor_count DESC;
