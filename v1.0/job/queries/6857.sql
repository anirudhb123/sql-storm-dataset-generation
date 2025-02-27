WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        c.name AS company_name,
        k.keyword,
        a.name AS actor_name
    FROM 
        aka_title t
    JOIN 
        movie_companies m ON t.id = m.movie_id
    JOIN 
        company_name c ON m.company_id = c.id
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
),
AggregateData AS (
    SELECT 
        movie_id, 
        title, 
        production_year, 
        COUNT(DISTINCT company_name) AS company_count,
        STRING_AGG(DISTINCT keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT actor_name, ', ') AS actors
    FROM 
        MovieDetails
    GROUP BY 
        movie_id, title, production_year
)
SELECT 
    production_year,
    COUNT(movie_id) AS movie_count,
    SUM(company_count) AS total_companies,
    ARRAY_AGG(DISTINCT keywords) AS all_keywords,
    ARRAY_AGG(DISTINCT actors) AS all_actors
FROM 
    AggregateData
GROUP BY 
    production_year
ORDER BY 
    production_year DESC;
