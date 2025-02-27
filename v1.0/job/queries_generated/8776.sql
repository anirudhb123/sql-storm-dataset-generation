WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        k.keyword AS movie_keyword,
        c.name AS company_name,
        p.name AS person_name,
        r.role AS person_role
    FROM 
        title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    JOIN 
        aka_name p ON ci.person_id = p.person_id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        role_type r ON ci.role_id = r.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
),
AggregatedResults AS (
    SELECT 
        production_year,
        COUNT(DISTINCT movie_id) AS total_movies,
        COUNT(DISTINCT person_name) AS total_actors,
        STRING_AGG(DISTINCT movie_keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT company_name, ', ') AS production_companies
    FROM 
        MovieDetails
    GROUP BY 
        production_year
)
SELECT 
    production_year,
    total_movies,
    total_actors,
    keywords,
    production_companies
FROM 
    AggregatedResults
ORDER BY 
    production_year DESC;
