WITH RECURSIVE MovieHierarchy AS (
    SELECT mt.id AS movie_id, mt.title, mt.production_year, 1 AS level
    FROM aka_title mt
    WHERE mt.production_year >= 2010

    UNION ALL

    SELECT t.id AS movie_id, t.title, t.production_year, mh.level + 1
    FROM movie_link ml
    JOIN MovieHierarchy mh ON ml.movie_id = mh.movie_id
    JOIN aka_title t ON ml.linked_movie_id = t.id
    WHERE mh.level < 3  -- Limit to 3 levels deep
),

TopMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        COUNT(DISTINCT ci.person_id) AS num_of_cast,
        ARRAY_AGG(DISTINCT a.name) AS cast_names,
        SUM(CASE WHEN mi.info_type_id = 1 THEN LENGTH(mi.info) END) AS description_length  -- Hypothetical info_type_id 1 indicates descriptions
    FROM aka_title mt
    LEFT JOIN cast_info ci ON mt.id = ci.movie_id
    LEFT JOIN aka_name a ON ci.person_id = a.person_id
    LEFT JOIN movie_info mi ON mt.id = mi.movie_id
    WHERE mt.production_year BETWEEN 2000 AND 2020
    GROUP BY mt.id, mt.title
    HAVING COUNT(DISTINCT ci.person_id) > 5 -- More than 5 cast members
),

RankedMovies AS (
    SELECT
        tm.movie_id,
        tm.title,
        tm.num_of_cast,
        tm.cast_names,
        tm.description_length,
        ROW_NUMBER() OVER (ORDER BY tm.num_of_cast DESC, tm.description_length DESC) AS rank
    FROM TopMovies tm
)

SELECT 
    rm.movie_id,
    rm.title,
    rm.num_of_cast,
    rm.cast_names,
    rm.description_length,
    mh.level AS movie_level -- Level from the recursive CTE
FROM RankedMovies rm
LEFT JOIN MovieHierarchy mh ON rm.movie_id = mh.movie_id
WHERE rm.rank <= 10 -- Top 10 ranked movies
ORDER BY rm.rank, mh.level ASC;
