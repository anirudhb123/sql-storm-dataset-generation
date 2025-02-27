WITH ActorMovieCounts AS (
    SELECT
        ak.person_id,
        COUNT(DISTINCT c.movie_id) AS total_movies,
        STRING_AGG(DISTINCT t.title, ', ') AS movie_titles
    FROM
        aka_name ak
    JOIN 
        cast_info c ON ak.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    GROUP BY
        ak.person_id
),
TopActors AS (
    SELECT
        ak.id,
        ak.name,
        amc.total_movies,
        amc.movie_titles
    FROM
        aka_name ak
    JOIN
        ActorMovieCounts amc ON ak.person_id = amc.person_id
    WHERE
        amc.total_movies > 5
),
MovieDetails AS (
    SELECT
        t.title,
        t.production_year,
        c.name AS company_name,
        ct.kind AS company_type
    FROM
        aka_title t
    JOIN
        movie_companies mc ON t.id = mc.movie_id
    JOIN
        company_name c ON mc.company_id = c.id
    JOIN
        company_type ct ON mc.company_type_id = ct.id
)
SELECT
    ta.name AS actor_name,
    ta.total_movies,
    ta.movie_titles,
    md.title AS movie_title,
    md.production_year,
    md.company_name,
    md.company_type
FROM
    TopActors ta
JOIN
    MovieDetails md ON ta.movie_titles LIKE '%' || md.title || '%'
ORDER BY
    ta.total_movies DESC, md.production_year DESC;
