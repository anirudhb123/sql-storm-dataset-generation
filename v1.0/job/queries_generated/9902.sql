WITH movie_data AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        k.keyword AS movie_keyword,
        cct.kind AS comp_cast_type,
        cn.name AS company_name,
        pi.info AS person_info,
        a.name AS actor_name
    FROM 
        aka_title t
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
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        comp_cast_type cct ON ci.person_role_id = cct.id
    LEFT JOIN 
        person_info pi ON a.person_id = pi.person_id
    WHERE 
        t.production_year > 2000 
        AND k.keyword LIKE '%action%'
)
SELECT 
    movie_id,
    movie_title,
    production_year,
    STRING_AGG(DISTINCT movie_keyword, ', ') AS keywords,
    STRING_AGG(DISTINCT actor_name, ', ') AS actors,
    STRING_AGG(DISTINCT company_name, ', ') AS companies,
    STRING_AGG(DISTINCT person_info, ', ') AS personal_info
FROM 
    movie_data
GROUP BY 
    movie_id, movie_title, production_year
ORDER BY 
    production_year DESC, movie_title;
