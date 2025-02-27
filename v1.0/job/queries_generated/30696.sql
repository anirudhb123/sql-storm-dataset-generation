WITH RECURSIVE MovieHierarchy AS (
    SELECT
        mt.title,
        mt.production_year,
        1 AS level,
        mt.id AS movie_id,
        NULL::integer AS parent_movie_id
    FROM
        aka_title mt
    WHERE
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    UNION ALL
    SELECT
        mt.title,
        mt.production_year,
        mh.level + 1,
        mt.id AS movie_id,
        mh.movie_id AS parent_movie_id
    FROM
        movie_link ml
    JOIN
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
    JOIN
        aka_title mt ON ml.linked_movie_id = mt.id
    WHERE
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
),
AggregateCast AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_actors,
        STRING_AGG(DISTINCT ak.name, ', ') AS actor_names
    FROM
        cast_info ci
    JOIN
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY
        ci.movie_id
),
TopMovies AS (
    SELECT
        title,
        production_year,
        total_actors,
        actor_names,
        ROW_NUMBER() OVER (ORDER BY total_actors DESC) AS rn
    FROM
        AggregateCast ac
    JOIN
        aka_title at ON ac.movie_id = at.id
)
SELECT
    mh.title AS Movie_Title,
    mh.production_year AS Release_Year,
    tm.total_actors AS Actor_Count,
    tm.actor_names AS Actors,
    COUNT(DISTINCT mc.company_id) AS Production_Companies,
    MAX(CASE WHEN mi.note IS NOT NULL THEN mi.info END) AS Additional_Info
FROM
    MovieHierarchy mh
LEFT JOIN
    TopMovies tm ON mh.movie_id = tm.movie_id
LEFT JOIN
    movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN
    movie_info mi ON mh.movie_id = mi.movie_id
WHERE
    mh.level = 1
    AND (tm.rn BETWEEN 1 AND 10 OR tm.rn IS NULL)
GROUP BY
    mh.title, mh.production_year, tm.total_actors, tm.actor_names
ORDER BY
    Actor_Count DESC,
    Release_Year DESC;
