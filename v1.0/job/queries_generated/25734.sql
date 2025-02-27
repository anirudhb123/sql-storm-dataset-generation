WITH MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        k.keyword AS movie_keyword,
        a.name AS actor_name,
        c.kind AS role
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
        role_type c ON ci.role_id = c.id
    WHERE 
        t.production_year >= 2000
)

SELECT 
    movie_title,
    production_year,
    STRING_AGG(DISTINCT CONCAT(actor_name, ' (', role, ')'), ', ') AS cast_info,
    STRING_AGG(DISTINCT movie_keyword, ', ') AS keywords
FROM 
    MovieDetails
GROUP BY 
    movie_title, production_year
ORDER BY 
    production_year DESC;
