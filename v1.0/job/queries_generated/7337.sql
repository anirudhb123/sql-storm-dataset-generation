WITH MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        c.kind AS company_type,
        k.keyword AS movie_keyword,
        a.name AS actor_name,
        CAST(COALESCE(COUNT(DISTINCT m.id), 0) AS integer) AS total_movies
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
        cast_info ci ON cc.subject_id = ci.id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    WHERE 
        t.production_year >= 2000 
        AND c.country_code = 'USA'
    GROUP BY 
        t.title, t.production_year, c.kind, k.keyword, a.name
)
SELECT 
    movie_title, 
    production_year, 
    company_type, 
    movie_keyword, 
    actor_name, 
    total_movies
FROM 
    MovieDetails
ORDER BY 
    production_year DESC, 
    total_movies DESC 
LIMIT 100;
