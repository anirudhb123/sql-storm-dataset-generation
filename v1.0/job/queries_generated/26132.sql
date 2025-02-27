WITH MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        c.name AS company_name,
        c.country_code,
        r.role AS actor_role,
        a.name AS actor_name,
        k.keyword AS movie_keyword
    FROM 
        title t
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
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year >= 2000 
        AND c.country_code = 'USA'
),
AggregatedData AS (
    SELECT 
        movie_title,
        production_year,
        STRING_AGG(DISTINCT actor_name, ', ') AS actors,
        STRING_AGG(DISTINCT company_name, ', ') AS production_companies,
        STRING_AGG(DISTINCT movie_keyword, ', ') AS keywords
    FROM 
        MovieDetails
    GROUP BY 
        movie_title, production_year
)
SELECT 
    movie_title,
    production_year,
    actors,
    production_companies,
    keywords
FROM 
    AggregatedData
ORDER BY 
    production_year DESC, movie_title;
