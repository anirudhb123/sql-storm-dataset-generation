WITH movie_data AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        a.name AS actor_name,
        k.keyword AS movie_keyword,
        c.kind AS company_type,
        tc.role AS role_name,
        mi.info AS movie_info
    FROM 
        title t
    INNER JOIN 
        complete_cast cc ON t.id = cc.movie_id
    INNER JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    INNER JOIN 
        aka_name a ON ci.person_id = a.person_id
    INNER JOIN 
        movie_companies mc ON t.id = mc.movie_id
    INNER JOIN 
        company_name cn ON mc.company_id = cn.id
    INNER JOIN 
        company_type ct ON mc.company_type_id = ct.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        role_type tc ON ci.role_id = tc.id
    LEFT JOIN 
        movie_info mi ON t.id = mi.movie_id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
        AND ci.note IS NULL
        AND a.name IS NOT NULL
    ORDER BY 
        t.production_year DESC, actor_name
)
SELECT 
    movie_title,
    production_year,
    STRING_AGG(DISTINCT actor_name, ', ') AS actors,
    STRING_AGG(DISTINCT movie_keyword, ', ') AS keywords,
    STRING_AGG(DISTINCT company_type, ', ') AS companies,
    STRING_AGG(DISTINCT role_name, ', ') AS roles,
    STRING_AGG(DISTINCT movie_info, ', ') AS additional_info
FROM 
    movie_data
GROUP BY 
    movie_title, production_year
HAVING 
    COUNT(DISTINCT actor_name) > 1
ORDER BY 
    production_year DESC;
