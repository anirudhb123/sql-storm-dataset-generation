WITH movie_data AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        c.kind AS company_type,
        k.keyword AS movie_keyword,
        a.name AS actor_name,
        p.info AS person_info
    FROM 
        aka_title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON ci.movie_id = t.id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        person_info p ON a.person_id = p.person_id
    WHERE 
        t.production_year >= 2000
        AND k.keyword LIKE '%action%'
)
SELECT 
    movie_title,
    production_year,
    company_type,
    STRING_AGG(DISTINCT movie_keyword, ', ') AS keywords,
    STRING_AGG(DISTINCT actor_name, ', ') AS cast,
    STRING_AGG(DISTINCT person_info, ', ') AS personal_info
FROM 
    movie_data
GROUP BY 
    movie_title, production_year, company_type
ORDER BY 
    production_year DESC, movie_title;
