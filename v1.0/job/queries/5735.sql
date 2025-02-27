WITH MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        c.kind AS company_type,
        k.keyword AS movie_keyword,
        a.name AS actor_name
    FROM 
        title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_type c ON mc.company_type_id = c.id
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
    WHERE 
        t.production_year > 2000
        AND c.kind IS NOT NULL
        AND k.keyword IS NOT NULL
), AggregatedData AS (
    SELECT 
        movie_title,
        production_year,
        company_type,
        COUNT(DISTINCT actor_name) AS unique_actors,
        STRING_AGG(DISTINCT movie_keyword, ', ') AS keywords
    FROM 
        MovieDetails
    GROUP BY 
        movie_title, production_year, company_type
)
SELECT 
    movie_title,
    production_year,
    company_type,
    unique_actors,
    keywords
FROM 
    AggregatedData
WHERE 
    unique_actors >= 5
ORDER BY 
    production_year DESC, unique_actors DESC;
