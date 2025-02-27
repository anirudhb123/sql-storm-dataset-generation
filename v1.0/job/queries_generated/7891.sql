WITH MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        c.company_id,
        c.note AS company_note,
        a.name AS actor_name,
        k.keyword AS movie_keyword
    FROM 
        title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year >= 2000
        AND ci.nr_order IS NOT NULL
),
AggregateDetails AS (
    SELECT 
        movie_title,
        production_year,
        ARRAY_AGG(DISTINCT actor_name) AS actors,
        ARRAY_AGG(DISTINCT company_note) AS companies,
        ARRAY_AGG(DISTINCT movie_keyword) AS keywords
    FROM 
        MovieDetails
    GROUP BY 
        movie_title, production_year
)
SELECT 
    movie_title,
    production_year,
    actors,
    companies,
    keywords
FROM 
    AggregateDetails
ORDER BY 
    production_year DESC, movie_title;
