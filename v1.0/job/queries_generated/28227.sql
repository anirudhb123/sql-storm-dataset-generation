WITH MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        k.keyword AS movie_keyword,
        c.name AS company_name,
        p.name AS person_name
    FROM 
        title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name p ON ci.person_id = p.person_id
    WHERE 
        t.production_year >= 2000
        AND k.keyword LIKE '%action%'
),
AggregatedData AS (
    SELECT 
        movie_title,
        production_year,
        STRING_AGG(DISTINCT movie_keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT company_name, ', ') AS companies,
        STRING_AGG(DISTINCT person_name, ', ') AS cast
    FROM 
        MovieDetails
    GROUP BY 
        movie_title, production_year
)
SELECT 
    movie_title,
    production_year,
    keywords,
    companies,
    cast
FROM 
    AggregatedData
ORDER BY 
    production_year DESC, movie_title;

This SQL query retrieves a detailed list of movies produced since the year 2000 that are categorized under the "action" keyword. It aggregates relevant details including keywords, associated companies, and cast members, with a focus on string processing via the `STRING_AGG` function to concatenate and summarize the information for easier readability. The final results are ordered by production year descending and then by movie title.
