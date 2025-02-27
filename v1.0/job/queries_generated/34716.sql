WITH RECURSIVE MovieHierarchy AS (
    SELECT m.id AS movie_id, m.title, m.production_year, 1 AS level
    FROM aka_title m
    WHERE m.production_year > 2000
    UNION ALL
    SELECT m.id AS movie_id, m.title, m.production_year, h.level + 1
    FROM aka_title m
    JOIN movie_link ml ON ml.movie_id = h.movie_id
    JOIN aka_title h ON h.id = ml.linked_movie_id
    WHERE h.production_year > m.production_year
),
MovieDetails AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COALESCE(mk.keyword, 'Unknown') AS keyword,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM aka_title m
    LEFT JOIN movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN cast_info ci ON m.id = ci.movie_id
    WHERE m.production_year BETWEEN 2000 AND 2023
    GROUP BY m.id, m.title, m.production_year, mk.keyword
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        keyword,
        cast_count,
        ROW_NUMBER() OVER (PARTITION BY keyword ORDER BY cast_count DESC) AS rn
    FROM MovieDetails
)
SELECT
    th.movie_id,
    th.title,
    th.production_year,
    th.keyword,
    th.cast_count,
    mh.level
FROM TopMovies th
LEFT JOIN MovieHierarchy mh ON th.movie_id = mh.movie_id
WHERE th.rn <= 5
ORDER BY th.keyword, th.cast_count DESC, th.title;
