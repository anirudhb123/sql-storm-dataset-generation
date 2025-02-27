WITH MovieInfo AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        rt.role AS role_name,
        ak.name AS actor_name,
        c.name AS company_name,
        k.keyword AS keyword,
        m.info AS movie_info
    FROM 
        title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name ak ON ak.person_id = ci.person_id
    JOIN 
        role_type rt ON rt.id = ci.role_id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON c.id = mc.company_id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN 
        keyword k ON k.id = mk.keyword_id
    LEFT JOIN 
        movie_info m ON m.movie_id = t.id
    WHERE 
        t.production_year >= 2000
),
AggregatedData AS (
    SELECT 
        movie_id,
        title,
        production_year,
        STRING_AGG(DISTINCT actor_name, ', ') AS actors,
        STRING_AGG(DISTINCT company_name, ', ') AS companies,
        STRING_AGG(DISTINCT keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT movie_info, ', ') AS additional_info
    FROM 
        MovieInfo
    GROUP BY 
        movie_id, title, production_year
)
SELECT 
    movie_id,
    title,
    production_year,
    actors,
    companies,
    keywords,
    additional_info
FROM 
    AggregatedData
ORDER BY 
    production_year DESC, title;
