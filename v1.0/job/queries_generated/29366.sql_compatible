
WITH ActorRoles AS (
    SELECT
        a.id AS actor_id,
        a.name AS actor_name,
        STRING_AGG(DISTINCT rt.role, ', ') AS roles,
        COUNT(DISTINCT ci.movie_id) AS total_movies
    FROM
        aka_name a
    JOIN
        cast_info ci ON a.person_id = ci.person_id
    JOIN
        role_type rt ON ci.role_id = rt.id
    GROUP BY
        a.id, a.name
),
MovieDetails AS (
    SELECT
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        COUNT(DISTINCT mc.company_id) AS production_companies,
        COUNT(DISTINCT mk.keyword_id) AS keywords_count
    FROM
        aka_title t
    LEFT JOIN
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN
        movie_keyword mk ON t.id = mk.movie_id
    GROUP BY
        t.id, t.title, t.production_year
),
TopActors AS (
    SELECT 
        actor_id,
        actor_name,
        total_movies
    FROM 
        ActorRoles
    WHERE
        total_movies > 5
    ORDER BY
        total_movies DESC
    LIMIT 10
)
SELECT
    ta.actor_name,
    ta.total_movies,
    md.movie_title,
    md.production_year,
    md.production_companies,
    md.keywords_count
FROM
    TopActors ta
JOIN
    cast_info ci ON ta.actor_id = ci.person_id
JOIN
    MovieDetails md ON ci.movie_id = md.movie_id
ORDER BY
    ta.total_movies DESC, md.production_year DESC;
