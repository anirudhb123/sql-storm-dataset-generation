WITH MovieDetails AS (
    SELECT
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        a.name AS actor_name,
        c.kind AS company_type,
        k.keyword AS movie_keyword,
        COALESCE(mi.info, 'N/A') AS movie_info
    FROM
        aka_title t
    JOIN
        complete_cast cc ON t.id = cc.movie_id
    JOIN
        aka_name a ON cc.subject_id = a.person_id
    JOIN
        movie_companies mc ON t.id = mc.movie_id
    JOIN
        company_type c ON mc.company_type_id = c.id
    LEFT JOIN
        movie_info mi ON t.id = mi.movie_id
    LEFT JOIN
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN
        keyword k ON mk.keyword_id = k.id
    WHERE
        a.name IS NOT NULL AND c.kind IS NOT NULL
),
AggregatedResults AS (
    SELECT
        movie_id,
        movie_title,
        production_year,
        STRING_AGG(DISTINCT actor_name, ', ') AS actors,
        STRING_AGG(DISTINCT company_type, ', ') AS companies,
        STRING_AGG(DISTINCT movie_keyword, ', ') AS keywords,
        MAX(movie_info) AS info
    FROM
        MovieDetails
    GROUP BY
        movie_id, movie_title, production_year
)
SELECT
    movie_id,
    movie_title,
    production_year,
    actors,
    companies,
    keywords,
    info
FROM
    AggregatedResults
ORDER BY
    production_year DESC, movie_title;
