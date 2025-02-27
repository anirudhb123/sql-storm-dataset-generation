WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        k.keyword,
        c.kind AS company_type,
        co.name AS company_name,
        p.info AS person_info,
        a.name AS aka_name
    FROM 
        title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name co ON mc.company_id = co.id
    JOIN 
        company_type c ON mc.company_type_id = c.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    JOIN 
        aka_name a ON ci.person_role_id = a.id
    LEFT JOIN 
        person_info p ON ci.person_id = p.person_id AND p.info_type_id = 1
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
)
SELECT 
    movie_id, 
    title, 
    production_year, 
    STRING_AGG(DISTINCT keyword, ', ') AS keywords,
    STRING_AGG(DISTINCT company_name, ', ') AS companies,
    STRING_AGG(DISTINCT company_type, ', ') AS company_types,
    STRING_AGG(DISTINCT aka_name, ', ') AS aliases,
    STRING_AGG(DISTINCT person_info, ', ') AS person_info_detail
FROM 
    MovieDetails
GROUP BY 
    movie_id, title, production_year
ORDER BY 
    production_year DESC, title;
