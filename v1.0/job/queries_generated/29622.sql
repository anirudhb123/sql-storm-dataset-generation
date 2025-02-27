WITH RankedTitles AS (
    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id,
        RANK() OVER (PARTITION BY t.production_year ORDER BY LENGTH(t.title) DESC) AS title_rank
    FROM
        aka_title t
    WHERE
        t.production_year IS NOT NULL
),
ActorStats AS (
    SELECT
        c.person_id,
        a.name AS actor_name,
        COUNT(DISTINCT c.movie_id) AS movies_count,
        STRING_AGG(DISTINCT tt.title, ', ') AS titles
    FROM
        cast_info c
    JOIN
        aka_name a ON c.person_id = a.person_id
    JOIN
        RankedTitles tt ON c.movie_id = tt.title_id
    GROUP BY
        c.person_id, a.name
),
PopularActors AS (
    SELECT
        actor_name,
        movies_count
    FROM
        ActorStats
    WHERE
        movies_count > 5
),
TopActors AS (
    SELECT
        actor_name,
        movies_count,
        RANK() OVER (ORDER BY movies_count DESC) AS rank
    FROM
        PopularActors
)
SELECT
    ta.actor_name,
    ta.movies_count,
    tt.production_year,
    STRING_AGG(tt.title, ', ') AS titles_in_top_year
FROM
    TopActors ta
JOIN
    cast_info ci ON ta.actor_name = (SELECT name FROM aka_name WHERE person_id = ci.person_id)
JOIN
    rankedTitles tt ON ci.movie_id = tt.title_id
WHERE
    tt.title_rank = 1
GROUP BY
    ta.actor_name, ta.movies_count, tt.production_year
ORDER BY
    ta.movies_count DESC, tt.production_year DESC;
