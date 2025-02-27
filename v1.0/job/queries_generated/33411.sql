WITH RECURSIVE MovieHierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        0 AS level
    FROM
        aka_title AS mt
    WHERE
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')

    UNION ALL

    SELECT
        ml.linked_movie_id,
        mt.title,
        mt.production_year,
        mh.level + 1
    FROM
        movie_link AS ml
    JOIN
        MovieHierarchy AS mh ON ml.movie_id = mh.movie_id
    JOIN
        aka_title AS mt ON ml.linked_movie_id = mt.id
)

SELECT
    m.title AS Movie_Title,
    m.production_year AS Production_Year,
    COALESCE(ca.name, '(No Cast)') AS Main_Cast,
    pg.name AS Production_Company,
    COUNT(DISTINCT mk.keyword) AS Keyword_Count,
    AVG(NULLIF(CASE WHEN b.status_id IS NOT NULL THEN b.status_id END, 0)) AS Average_Status,
    ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.title) AS Rank_By_Year
FROM
    MovieHierarchy AS m
LEFT JOIN
    complete_cast AS b ON m.movie_id = b.movie_id
LEFT JOIN
    cast_info AS ci ON m.movie_id = ci.movie_id
LEFT JOIN
    aka_name AS ca ON ci.person_id = ca.person_id
LEFT JOIN
    movie_companies AS mc ON m.movie_id = mc.movie_id
LEFT JOIN
    company_name AS pg ON mc.company_id = pg.id
LEFT JOIN
    movie_keyword AS mk ON m.movie_id = mk.movie_id
WHERE
    m.production_year >= 2000
GROUP BY
    m.movie_id, pg.name, ca.name
HAVING
    COUNT(DISTINCT mk.keyword) > 1
ORDER BY
    Rank_By_Year, m.title;
