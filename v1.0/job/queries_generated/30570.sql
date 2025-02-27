WITH RECURSIVE MovieHierarchy AS (
    SELECT mt.id AS movie_id, mt.title, mt.production_year, 1 AS level
    FROM aka_title mt
    WHERE mt.production_year IS NOT NULL
    UNION ALL
    SELECT mt2.id AS movie_id, mt2.title, mt2.production_year, mh.level + 1
    FROM movie_link ml
    JOIN MovieHierarchy mh ON ml.movie_id = mh.movie_id
    JOIN aka_title mt2 ON ml.linked_movie_id = mt2.id
    WHERE mt2.production_year IS NOT NULL
),
TopMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actors
    FROM aka_title m
    LEFT JOIN cast_info c ON m.id = c.movie_id
    LEFT JOIN aka_name a ON c.person_id = a.person_id
    GROUP BY m.id, m.title, m.production_year
    HAVING COUNT(DISTINCT c.person_id) > 3
),
AverageRatings AS (
    SELECT 
        mt.movie_id, 
        AVG(COALESCE(r.rating, 0)) AS avg_rating
    FROM (
        SELECT DISTINCT movie_id 
        FROM movie_companies
        WHERE company_type_id IN (SELECT id FROM company_type WHERE kind = 'Distributor')
    ) AS mt
    LEFT JOIN movie_info mi ON mt.movie_id = mi.movie_id AND mi.info_type_id = (
        SELECT id FROM info_type WHERE info = 'rating'
    )
    LEFT JOIN (
        SELECT movie_id, CAST(info AS FLOAT) AS rating
        FROM movie_info
        WHERE info_type_id IN (SELECT id FROM info_type WHERE info = 'rating')
    ) r ON mt.movie_id = r.movie_id
    GROUP BY mt.movie_id
)
SELECT 
    th.movie_id,
    th.title,
    th.production_year,
    th.cast_count,
    th.actors,
    COALESCE(ar.avg_rating, 0) AS avg_rating,
    mh.level
FROM TopMovies th
LEFT JOIN AverageRatings ar ON th.movie_id = ar.movie_id
LEFT JOIN MovieHierarchy mh ON th.movie_id = mh.movie_id
WHERE th.production_year >= 2000
ORDER BY th.avg_rating DESC, th.title ASC
LIMIT 10;
