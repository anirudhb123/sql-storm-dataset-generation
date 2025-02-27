WITH Recursive_Actor_Movies AS (
    SELECT
        a.id AS actor_id,
        a.name AS actor_name,
        c.movie_id,
        t.title AS movie_title,
        t.production_year
    FROM
        aka_name a
    JOIN
        cast_info c ON a.person_id = c.person_id
    JOIN
        title t ON c.movie_id = t.id
    WHERE
        a.name ILIKE '%John%'
),
Distinct_Movies AS (
    SELECT DISTINCT
        actor_id,
        actor_name,
        movie_id,
        movie_title,
        production_year
    FROM
        Recursive_Actor_Movies
),
Keyword_Info AS (
    SELECT
        d.actor_id,
        d.actor_name,
        d.movie_id,
        d.movie_title,
        d.production_year,
        k.keyword
    FROM
        Distinct_Movies d
    JOIN
        movie_keyword mk ON d.movie_id = mk.movie_id
    JOIN
        keyword k ON mk.keyword_id = k.id
)
SELECT
    actor_name,
    COUNT(DISTINCT movie_id) AS total_movies,
    STRING_AGG(DISTINCT movie_title || ' (' || production_year || ')', ', ') AS movie_list,
    STRING_AGG(DISTINCT keyword, ', ') AS associated_keywords
FROM
    Keyword_Info
GROUP BY
    actor_name
ORDER BY
    total_movies DESC
LIMIT 10;

