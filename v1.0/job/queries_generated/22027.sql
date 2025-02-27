WITH RECURSIVE MovieHierarchy AS (
    SELECT
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        ARRAY[m.title] AS title_path
    FROM
        aka_title m
    WHERE
        m.production_year IS NOT NULL

    UNION ALL

    SELECT
        mk.linked_movie_id,
        mk.linked_movie_id::text || ' (linked)' AS movie_title,
        NULL AS production_year,
        mh.title_path || mk.linked_movie_id::text
    FROM
        movie_link mk
    JOIN
        MovieHierarchy mh ON mk.movie_id = mh.movie_id
),
ActorMovie AS (
    SELECT
        a.id AS actor_id,
        ak.name AS actor_name,
        c.movie_id,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY m.production_year DESC) AS latest_movie_rank
    FROM
        aka_name ak
    JOIN
        cast_info c ON ak.person_id = c.person_id
    JOIN
        aka_title m ON c.movie_id = m.movie_id
    WHERE
        ak.name IS NOT NULL AND ak.name != ''
),
ActorWithMovies AS (
    SELECT
        am.actor_id,
        am.actor_name,
        mh.movie_title,
        mh.production_year,
        am.latest_movie_rank,
        COALESCE(mk.keyword, 'No Keywords') AS keyword
    FROM
        ActorMovie am
    LEFT JOIN
        MovieHierarchy mh ON am.movie_id = mh.movie_id
    LEFT JOIN
        movie_keyword mk ON mh.movie_id = mk.movie_id
    WHERE
        am.latest_movie_rank = 1
)
SELECT
    actor_name,
    COUNT(DISTINCT movie_title) AS total_movies,
    STRING_AGG(DISTINCT keyword, ', ') AS keywords,
    MAX(production_year) AS last_movie_year
FROM
    ActorWithMovies
GROUP BY
    actor_name
HAVING
    COUNT(DISTINCT movie_title) > 1
ORDER BY
    total_movies DESC NULLS LAST,
    last_movie_year DESC;
