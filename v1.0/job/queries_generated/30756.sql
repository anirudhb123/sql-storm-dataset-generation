WITH RECURSIVE movie_hierarchy AS (
    SELECT
        m.id AS movie_id,
        m.title,
        1 AS level,
        COALESCE(mk.keyword, 'No Keywords') AS keyword
    FROM
        aka_title m
    LEFT JOIN
        movie_keyword mk ON m.id = mk.movie_id
    WHERE
        m.production_year >= 2000

    UNION ALL

    SELECT
        m.id AS movie_id,
        m.title,
        mh.level + 1,
        COALESCE(mk.keyword, 'No Keywords') AS keyword
    FROM
        aka_title m
    JOIN
        movie_link ml ON m.id = ml.movie_id
    JOIN
        movie_hierarchy mh ON ml.linked_movie_id = mh.movie_id
)

SELECT
    mh.title AS Movie_Title,
    mh.level AS Movie_Level,
    COUNT(DISTINCT ci.person_id) AS Cast_Count,
    STRING_AGG(DISTINCT a.name, ', ') AS Cast_Names,
    AVG(m.production_year) AS Avg_Production_Year
FROM
    movie_hierarchy mh
LEFT JOIN
    cast_info ci ON mh.movie_id = ci.movie_id
LEFT JOIN
    aka_name a ON ci.person_id = a.person_id
LEFT JOIN
    aka_title m ON mh.movie_id = m.id
WHERE
    mh.keyword != 'No Keywords' AND
    (mh.level = 1 OR mh.level = 2)
GROUP BY
    mh.title,
    mh.level
ORDER BY
    Movie_Level ASC,
    Cast_Count DESC
LIMIT 100;
