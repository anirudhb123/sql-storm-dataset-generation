WITH MovieDetails AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        c.name AS company_name,
        a.name AS actor_name,
        k.keyword
    FROM 
        title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year >= 2000
        AND c.country_code = 'USA'
        AND k.keyword IS NOT NULL
)
SELECT 
    title_id,
    title,
    production_year,
    COUNT(DISTINCT actor_name) AS actor_count,
    STRING_AGG(DISTINCT company_name, ', ') AS companies,
    STRING_AGG(DISTINCT keyword, ', ') AS keywords
FROM 
    MovieDetails
GROUP BY 
    title_id, title, production_year
ORDER BY 
    production_year DESC, actor_count DESC;
