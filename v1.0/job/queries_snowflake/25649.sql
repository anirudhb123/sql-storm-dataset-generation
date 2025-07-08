
WITH RankedMovies AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        k.keyword AS movie_keyword,
        c.name AS company_name,
        r.role AS actor_role,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY a.production_year DESC) AS rank
    FROM 
        aka_title a 
    JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        movie_companies mc ON a.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        complete_cast cc ON a.id = cc.movie_id
    JOIN 
        cast_info ci ON ci.movie_id = cc.movie_id AND ci.person_id = cc.subject_id
    JOIN 
        role_type r ON ci.role_id = r.id
)
SELECT 
    movie_title, 
    production_year, 
    LISTAGG(DISTINCT movie_keyword, ', ') AS keywords,
    LISTAGG(DISTINCT company_name, ', ') AS companies,
    LISTAGG(DISTINCT actor_role, ', ') AS roles
FROM 
    RankedMovies
WHERE 
    rank = 1
GROUP BY 
    movie_title, production_year
ORDER BY 
    production_year DESC, movie_title ASC;
