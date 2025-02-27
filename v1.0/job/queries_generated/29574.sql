WITH MovieDetails AS (
    SELECT
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        GROUP_CONCAT(DISTINCT a.name) AS actor_names,
        GROUP_CONCAT(DISTINCT k.keyword) AS movie_keywords,
        GROUP_CONCAT(DISTINCT c.kind) AS company_types
    FROM
        title t
    JOIN
        movie_info mi ON t.id = mi.movie_id
    JOIN
        movie_keyword mk ON t.id = mk.movie_id
    JOIN
        keyword k ON mk.keyword_id = k.id
    JOIN
        movie_companies mc ON t.id = mc.movie_id
    JOIN
        company_type c ON mc.company_type_id = c.id
    LEFT JOIN
        cast_info ca ON t.id = ca.movie_id
    LEFT JOIN
        aka_name a ON ca.person_id = a.person_id
    WHERE
        t.production_year >= 2000
    GROUP BY
        t.id, t.title, t.production_year
),
HighRatedMovies AS (
    SELECT
        movie_id,
        movie_title,
        production_year,
        actor_names,
        movie_keywords,
        company_types,
        RANK() OVER (ORDER BY production_year DESC) AS ranking
    FROM
        MovieDetails
    WHERE
        actor_names IS NOT NULL AND
        movie_keywords IS NOT NULL AND
        company_types IS NOT NULL
)
SELECT
    *
FROM
    HighRatedMovies
WHERE
    ranking <= 50
ORDER BY
    production_year DESC, movie_title;
