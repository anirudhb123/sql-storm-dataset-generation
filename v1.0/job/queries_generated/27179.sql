WITH MovieDetails AS (
    SELECT 
        t.id AS title_id,
        t.title AS title,
        t.production_year,
        k.keyword AS movie_keyword,
        a.name AS actor_name,
        a.id AS actor_id,
        c.kind AS company_type,
        co.name AS company_name
    FROM 
        title t
    JOIN
        movie_keyword mk ON t.id = mk.movie_id
    JOIN
        keyword k ON mk.keyword_id = k.id
    JOIN
        cast_info ci ON t.id = ci.movie_id
    JOIN
        aka_name a ON ci.person_id = a.person_id
    JOIN
        movie_companies mc ON t.id = mc.movie_id
    JOIN
        company_name co ON mc.company_id = co.id
    JOIN
        company_type c ON mc.company_type_id = c.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
),
AggregatedMovieData AS (
    SELECT
        title_id,
        title,
        production_year,
        STRING_AGG(DISTINCT movie_keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT actor_name, ', ') AS actors,
        STRING_AGG(DISTINCT company_name, ', ') AS companies,
        STRING_AGG(DISTINCT company_type, ', ') AS company_types
    FROM 
        MovieDetails
    GROUP BY
        title_id, title, production_year
)
SELECT 
    title,
    production_year,
    keywords,
    actors,
    companies,
    company_types
FROM 
    AggregatedMovieData
ORDER BY 
    production_year DESC, title;
