WITH RECURSIVE ActorHierarchy AS (
    SELECT
        c.person_id,
        a.name AS actor_name,
        a.id AS actor_id,
        c.movie_id,
        t.title AS movie_title,
        t.production_year,
        1 AS depth
    FROM
        cast_info c
    JOIN
        aka_name a ON c.person_id = a.person_id
    JOIN
        aka_title t ON c.movie_id = t.movie_id
    WHERE
        c.nr_order = 1  -- Top billed actor
    UNION ALL
    SELECT
        c.person_id,
        a.name AS actor_name,
        a.id AS actor_id,
        c.movie_id,
        t.title AS movie_title,
        t.production_year,
        ah.depth + 1
    FROM
        cast_info c
    JOIN
        aka_name a ON c.person_id = a.person_id
    JOIN
        aka_title t ON c.movie_id = t.movie_id
    JOIN
        ActorHierarchy ah ON ah.movie_id = c.movie_id
    WHERE
        c.nr_order > 1  -- Other actors
),
MovieKeywords AS (
    SELECT
        m.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM
        movie_keyword m
    JOIN
        keyword k ON m.keyword_id = k.id
    GROUP BY
        m.movie_id
),
ActorMovies AS (
    SELECT
        ah.actor_id,
        ah.actor_name,
        COUNT(DISTINCT ah.movie_id) AS total_movies,
        AVG(ah.production_year) AS avg_year
    FROM
        ActorHierarchy ah
    GROUP BY
        ah.actor_id, ah.actor_name
)
SELECT
    am.actor_name,
    am.total_movies,
    am.avg_year,
    mk.keywords,
    CASE
        WHEN am.total_movies > 10 THEN 'Veteran Actor'
        WHEN am.total_movies BETWEEN 5 AND 10 THEN 'Emerging Actor'
        ELSE 'Novice Actor'
    END AS actor_status
FROM
    ActorMovies am
LEFT JOIN
    MovieKeywords mk ON mk.movie_id IN (
        SELECT movie_id FROM cast_info WHERE person_id = am.actor_id
    )
ORDER BY
    am.total_movies DESC,
    am.actor_name;

**Explanation:**
1. The first CTE (`ActorHierarchy`) builds a recursive structure of actors and their respective movies, capturing the hierarchy of cast roles.
2. The second CTE (`MovieKeywords`) aggregates keywords related to each movie using a `STRING_AGG` function.
3. The third CTE (`ActorMovies`) summarizes data for each actor, calculating the total number of movies they acted in and their average production year.
4. The main query selects from `ActorMovies`, incorporating keyword data through a `LEFT JOIN`. It also classifies actors based on their total movie count and orders the results by the total number of movies acted in and actor name.
