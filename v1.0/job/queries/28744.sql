WITH MovieDetails AS (
    SELECT 
        t.id AS title_id,
        t.title AS movie_title,
        t.production_year,
        k.keyword AS movie_keyword,
        c.name AS company_name,
        r.role AS person_role,
        a.name AS actor_name,
        p.info AS actor_info
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
        aka_name a ON ci.person_id = a.person_id 
    JOIN 
        role_type r ON ci.role_id = r.id
    LEFT JOIN 
        person_info p ON a.person_id = p.person_id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
        AND k.keyword IN ('Action', 'Drama')
),
AggregatedData AS (
    SELECT 
        production_year,
        COUNT(DISTINCT title_id) AS title_count,
        COUNT(DISTINCT actor_name) AS actor_count,
        STRING_AGG(DISTINCT movie_keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT company_name, ', ') AS companies
    FROM 
        MovieDetails
    GROUP BY 
        production_year
)
SELECT 
    production_year,
    title_count,
    actor_count,
    keywords,
    companies
FROM 
    AggregatedData
ORDER BY 
    production_year DESC;
