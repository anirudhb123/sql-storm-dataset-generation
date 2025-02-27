WITH MovieDetails AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        k.keyword,
        a.name AS actor_name,
        c.kind AS cast_type,
        mp.company_name AS production_company
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
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        movie_companies mc ON mc.movie_id = t.id
    JOIN 
        company_name mp ON mc.company_id = mp.id
    JOIN 
        kind_type kt ON t.kind_id = kt.id
    JOIN 
        comp_cast_type c ON ci.role_id = c.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
        AND k.keyword LIKE '%Action%'
    ORDER BY 
        t.production_year DESC
),
AggregateData AS (
    SELECT 
        production_year,
        COUNT(DISTINCT title_id) AS total_movies,
        COUNT(DISTINCT actor_name) AS total_actors,
        STRING_AGG(DISTINCT keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT production_company, ', ') AS production_companies
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
    AggregateData
ORDER BY 
    production_year DESC;
