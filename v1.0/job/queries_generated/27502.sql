WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id, 
        t.title, 
        t.production_year, 
        k.keyword, 
        c.name AS company_name,
        r.role AS person_role,
        a.name AS actor_name
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
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    JOIN 
        role_type r ON ci.role_id = r.id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    WHERE 
        t.production_year >= 2000 AND 
        k.keyword LIKE '%action%' AND 
        c.country_code IN ('US', 'GB')
),
AggregatedData AS (
    SELECT 
        production_year, 
        COUNT(movie_id) AS total_movies, 
        STRING_AGG(DISTINCT title, ', ') AS movie_titles,
        STRING_AGG(DISTINCT actor_name, ', ') AS cast_names,
        STRING_AGG(DISTINCT company_name, ', ') AS production_companies,
        STRING_AGG(DISTINCT keyword, ', ') AS movie_keywords
    FROM 
        MovieDetails
    GROUP BY 
        production_year
)
SELECT 
    production_year,
    total_movies,
    movie_titles,
    cast_names,
    production_companies,
    movie_keywords
FROM 
    AggregatedData
ORDER BY 
    production_year DESC;
