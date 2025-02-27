WITH RECURSIVE ActorMovies AS (
    SELECT
        c.person_id,
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        1 AS level
    FROM
        cast_info AS c
    JOIN
        aka_name AS a ON c.person_id = a.person_id
    JOIN
        aka_title AS t ON c.movie_id = t.movie_id
    WHERE
        c.nr_order = 1  -- Taking the lead role for simplicity
    UNION ALL
    SELECT
        c.person_id,
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        level + 1
    FROM
        ActorMovies AS am
    JOIN
        cast_info AS c ON am.movie_title = (SELECT title FROM aka_title WHERE movie_id = c.movie_id)
    JOIN
        aka_name AS a ON c.person_id = a.person_id
    JOIN
        aka_title AS t ON c.movie_id = t.movie_id
    WHERE
        am.level < 2 -- Limiting to a maximum of two levels deep
),
AggregatedMovies AS (
    SELECT
        actor_name,
        COUNT(DISTINCT movie_title) AS total_movies,
        ARRAY_AGG(DISTINCT movie_title ORDER BY production_year DESC) AS movies_list
    FROM
        ActorMovies
    GROUP BY
        actor_name
),
RankedActors AS (
    SELECT
        actor_name,
        total_movies,
        movies_list,
        RANK() OVER (ORDER BY total_movies DESC) AS movie_rank
    FROM
        AggregatedMovies
)
SELECT
    ra.actor_name,
    ra.total_movies,
    ra.movies_list,
    COALESCE(m.children_count, 0) AS children_count,
    m.production_year AS last_movie_year
FROM
    RankedActors AS ra
LEFT JOIN (
    SELECT
        c.person_id,
        COUNT(DISTINCT c2.movie_id) AS children_count,
        MAX(t.production_year) AS production_year
    FROM
        cast_info AS c
    JOIN
        cast_info AS c2 ON c.person_id = c2.person_id AND c.movie_id <> c2.movie_id
    JOIN
        aka_title AS t ON c2.movie_id = t.movie_id
    GROUP BY
        c.person_id
) AS m ON ra.actor_name = (SELECT name FROM aka_name WHERE person_id = m.person_id LIMIT 1)
WHERE
    ra.movie_rank <= 10
ORDER BY
    ra.total_movies DESC, ra.actor_name;
