WITH MovieDetails AS (
    SELECT 
        t.title, 
        t.production_year, 
        c.name AS company_name, 
        k.keyword, 
        n.name AS actor_name 
    FROM 
        title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    JOIN 
        aka_name n ON ci.person_id = n.person_id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
),
CompanyMovies AS (
    SELECT 
        company_name, 
        COUNT(DISTINCT title) AS movie_count 
    FROM 
        MovieDetails 
    GROUP BY 
        company_name 
)
SELECT 
    cm.company_name, 
    cm.movie_count, 
    COUNT(DISTINCT md.actor_name) AS actor_count 
FROM 
    CompanyMovies cm
JOIN 
    MovieDetails md ON cm.company_name = md.company_name
GROUP BY 
    cm.company_name, cm.movie_count
ORDER BY 
    cm.movie_count DESC, actor_count DESC
LIMIT 10;
