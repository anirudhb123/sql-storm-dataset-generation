WITH RECURSIVE MovieHierarchy AS (
    SELECT mt.id AS movie_id, mt.title, 
           mt.production_year, 
           mt.kind_id,
           0 AS level
    FROM aka_title mt
    WHERE mt.production_year >= 2000
    UNION ALL
    SELECT mt.id, mt.title, 
           mt.production_year, 
           mt.kind_id,
           mh.level + 1
    FROM aka_title mt
    INNER JOIN movie_link ml ON ml.linked_movie_id = mt.id
    INNER JOIN MovieHierarchy mh ON mh.movie_id = ml.movie_id
),
RankedMovies AS (
    SELECT 
        mh.title,
        mh.production_year,
        kh.keyword,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        RANK() OVER (PARTITION BY mh.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM MovieHierarchy mh
    LEFT JOIN movie_keyword mk ON mk.movie_id = mh.movie_id
    LEFT JOIN keyword kh ON kh.id = mk.keyword_id
    LEFT JOIN cast_info ci ON ci.movie_id = mh.movie_id
    GROUP BY mh.title, mh.production_year, kh.keyword
),
TopMovies AS (
    SELECT title, production_year, 
           STRING_AGG(DISTINCT keyword, ', ') AS keywords, 
           cast_count
    FROM RankedMovies
    WHERE rank = 1
    GROUP BY title, production_year, cast_count
)
SELECT 
    tm.title,
    tm.production_year,
    tm.keywords,
    tm.cast_count,
    COALESCE((SELECT AVG(cast_count) 
               FROM TopMovies 
               WHERE production_year = tm.production_year), 0) AS avg_cast_count,
    CASE 
        WHEN tm.cast_count > (SELECT AVG(cast_count) 
                               FROM TopMovies 
                               WHERE production_year = tm.production_year) 
        THEN 'Above Average'
        WHEN tm.cast_count = (SELECT AVG(cast_count) 
                               FROM TopMovies 
                               WHERE production_year = tm.production_year) 
        THEN 'Average'
        ELSE 'Below Average'
    END AS cast_performance
FROM TopMovies tm
ORDER BY tm.production_year DESC, tm.cast_count DESC;
