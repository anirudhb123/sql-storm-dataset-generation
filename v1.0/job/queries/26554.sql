WITH MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        t.kind_id,
        k.keyword AS movie_keyword,
        c.name AS company_name,
        a.name AS actor_name,
        p.gender AS actor_gender
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
        aka_name a ON cc.subject_id = a.person_id
    JOIN 
        name p ON a.person_id = p.imdb_id
    WHERE 
        k.keyword LIKE '%Action%' 
    AND 
        t.production_year BETWEEN 2000 AND 2023 
)
SELECT 
    movie_title,
    production_year,
    COUNT(DISTINCT actor_name) AS actor_count,
    STRING_AGG(DISTINCT movie_keyword, ', ') AS keywords,
    STRING_AGG(DISTINCT company_name, ', ') AS production_companies,
    STRING_AGG(DISTINCT actor_gender, ', ') AS actor_genders
FROM 
    MovieDetails
GROUP BY 
    movie_title, production_year
ORDER BY 
    production_year DESC,
    actor_count DESC;