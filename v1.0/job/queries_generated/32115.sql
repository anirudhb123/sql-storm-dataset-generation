WITH RECURSIVE MovieHierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        mt.kind_id,
        1 AS level
    FROM
        aka_title mt
    WHERE
        mt.production_year BETWEEN 2000 AND 2020

    UNION ALL

    SELECT
        ml.linked_movie_id AS movie_id,
        at.title AS movie_title,
        at.production_year,
        at.kind_id,
        mh.level + 1
    FROM
        movie_link ml
    JOIN
        aka_title at ON ml.linked_movie_id = at.id
    JOIN
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)
, MovieCast AS (
    SELECT
        mt.id AS movie_id,
        count(ci.person_id) AS actor_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS actors
    FROM
        aka_title mt
    LEFT JOIN
        cast_info ci ON mt.id = ci.movie_id
    LEFT JOIN
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY
        mt.id
)
, MovieInfo AS (
    SELECT
        mt.movie_id,
        mt.movie_title,
        mt.production_year,
        COALESCE(m.actor_count, 0) AS total_actors,
        COALESCE(m.actors, 'No actors') AS actor_list
    FROM
        MovieHierarchy mt
    LEFT JOIN
        MovieCast m ON mt.movie_id = m.movie_id
)
SELECT
    mi.movie_title,
    mi.production_year,
    mi.total_actors,
    mi.actor_list,
    CASE 
        WHEN mi.total_actors > 10 THEN 'Large Cast'
        WHEN mi.total_actors BETWEEN 5 AND 10 THEN 'Medium Cast'
        ELSE 'Small Cast'
    END AS cast_size,
    SUM(CASE 
            WHEN mi.production_year = 2020 THEN 1
            ELSE 0 
        END) OVER (PARTITION BY mi.production_year) AS 2020_movies_count
FROM
    MovieInfo mi
WHERE
    mi.production_year IS NOT NULL
ORDER BY
    mi.production_year DESC, 
    mi.total_actors DESC
LIMIT 50;
