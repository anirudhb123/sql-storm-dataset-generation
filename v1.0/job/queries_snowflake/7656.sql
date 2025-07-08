
WITH RankedMovies AS (
    SELECT
        t.title,
        t.production_year,
        a.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY c.nr_order) AS actor_rank
    FROM
        aka_title t
    JOIN
        complete_cast cc ON t.id = cc.movie_id
    JOIN
        cast_info c ON cc.subject_id = c.id
    JOIN
        aka_name a ON c.person_id = a.person_id
    WHERE
        t.production_year >= 2000
),
TopActors AS (
    SELECT
        actor_name,
        COUNT(*) AS movie_count
    FROM
        RankedMovies
    WHERE
        actor_rank <= 3
    GROUP BY
        actor_name
    HAVING
        COUNT(*) > 2
),
FinalSelection AS (
    SELECT
        a.name AS actor_name,
        COUNT(DISTINCT t.id) AS total_movies,
        LISTAGG(DISTINCT t.title, ', ') WITHIN GROUP (ORDER BY t.title) AS movie_titles
    FROM
        aka_name a
    JOIN
        cast_info c ON a.person_id = c.person_id
    JOIN
        complete_cast cc ON c.movie_id = cc.movie_id
    JOIN
        aka_title t ON cc.movie_id = t.id
    WHERE
        a.name IN (SELECT actor_name FROM TopActors)
    GROUP BY
        a.name
    ORDER BY
        total_movies DESC
)
SELECT 
    actor_name,
    total_movies,
    movie_titles
FROM 
    FinalSelection
LIMIT 10;
