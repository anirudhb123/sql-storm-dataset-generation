
WITH MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        a.name AS actor_name,
        p.gender,
        k.keyword AS movie_keyword,
        ct.kind AS company_type,
        i.info AS additional_info
    FROM 
        title t
    JOIN 
        aka_title at ON at.movie_id = t.id
    JOIN 
        cast_info ci ON ci.movie_id = t.id
    JOIN 
        aka_name a ON a.person_id = ci.person_id
    JOIN 
        name p ON p.id = a.person_id
    JOIN 
        movie_keyword mk ON mk.movie_id = t.id
    JOIN 
        keyword k ON k.id = mk.keyword_id
    JOIN 
        movie_companies mc ON mc.movie_id = t.id
    JOIN 
        company_name cn ON cn.id = mc.company_id
    JOIN 
        company_type ct ON ct.id = mc.company_type_id
    JOIN 
        movie_info mi ON mi.movie_id = t.id
    JOIN 
        info_type i ON i.id = mi.info_type_id
    WHERE 
        t.production_year BETWEEN 1990 AND 2020
        AND p.gender IN ('M', 'F')
)
SELECT 
    movie_title, 
    production_year, 
    STRING_AGG(DISTINCT actor_name, ', ') AS actors, 
    STRING_AGG(DISTINCT movie_keyword, ', ') AS keywords,
    STRING_AGG(DISTINCT company_type, ', ') AS companies,
    STRING_AGG(DISTINCT additional_info, ', ') AS additional_info
FROM 
    MovieDetails
GROUP BY 
    movie_title, 
    production_year
ORDER BY 
    production_year DESC, 
    movie_title ASC;
