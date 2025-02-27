WITH MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        k.keyword AS movie_keyword,
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
        t.production_year >= 2000
        AND k.keyword LIKE '%action%'
),
AggregatedData AS (
    SELECT 
        movie_title,
        production_year,
        array_agg(DISTINCT movie_keyword) AS keywords,
        array_agg(DISTINCT company_name) AS companies,
        array_agg(DISTINCT actor_name) AS actors,
        array_agg(DISTINCT person_role) AS roles
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
    actors,
    roles,
    COUNT(*) OVER() AS total_movies
FROM 
    AggregatedData
ORDER BY 
    production_year DESC, movie_title;
