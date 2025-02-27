WITH RankedMovies AS (
    SELECT
        t.title AS movie_title,
        t.production_year,
        a.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY a.name) AS actor_rank
    FROM
        aka_name a
    JOIN
        cast_info c ON a.person_id = c.person_id
    JOIN
        aka_title t ON c.movie_id = t.movie_id
    WHERE
        a.name IS NOT NULL
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

MovieDetails AS (
    SELECT
        m.movie_id,
        t.title,
        m.production_year,
        mk.keywords,
        ROW_NUMBER() OVER (PARTITION BY m.movie_id ORDER BY t.title) AS title_rank
    FROM
        aka_title t
    JOIN
        RankedMovies rm ON t.id = rm.movie_title
    JOIN
        MovieKeywords mk ON t.id = mk.movie_id
)

SELECT
    d.title,
    d.production_year,
    d.keywords,
    COUNT(DISTINCT rm.actor_name) AS total_actors,
    COUNT(DISTINCT c.id) AS total_cast_roles
FROM
    MovieDetails d
JOIN
    cast_info c ON d.movie_id = c.movie_id
JOIN
    ranked_movies rm ON c.movie_id = rm.movie_title
WHERE
    d.production_year >= 1990
GROUP BY
    d.title,
    d.production_year,
    d.keywords
ORDER BY
    d.production_year DESC, 
    d.title ASC;
