WITH RankedTitles AS (
    SELECT
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER(PARTITION BY a.person_id ORDER BY t.production_year DESC) AS title_rank
    FROM
        aka_name a
    JOIN
        cast_info ci ON a.person_id = ci.person_id
    JOIN
        aka_title t ON ci.movie_id = t.movie_id
    WHERE
        a.name IS NOT NULL
        AND t.production_year IS NOT NULL
),
ActorCounts AS (
    SELECT
        actor_name,
        COUNT(movie_title) AS total_movies
    FROM
        RankedTitles
    WHERE
        title_rank <= 5
    GROUP BY
        actor_name
),
TopActors AS (
    SELECT
        actor_name,
        total_movies,
        DENSE_RANK() OVER(ORDER BY total_movies DESC) AS rank
    FROM
        ActorCounts
    LIMIT 10
)
SELECT
    a.actor_name,
    a.total_movies,
    GROUP_CONCAT(t.movie_title || ' (' || t.production_year || ')') AS movie_list
FROM
    TopActors a
JOIN
    RankedTitles t ON a.actor_name = t.actor_name
WHERE
    t.title_rank <= 5
GROUP BY
    a.actor_name, a.total_movies
ORDER BY
    a.total_movies DESC;
