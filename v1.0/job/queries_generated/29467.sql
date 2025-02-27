WITH movie_data AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        GROUP_CONCAT(CONCAT(an.name, '(', rc.role, ')') ORDER BY rc.nr_order) AS cast_list,
        k.keyword AS keyword_used,
        c.name AS company_name,
        ct.kind AS company_type
    FROM 
        aka_title t
    JOIN 
        cast_info rc ON t.id = rc.movie_id
    JOIN 
        aka_name an ON rc.person_id = an.person_id
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year, k.keyword, c.name, ct.kind
    ORDER BY 
        t.production_year DESC
)
SELECT 
    movie_title,
    production_year,
    cast_list,
    keyword_used,
    company_name,
    company_type
FROM 
    movie_data
WHERE 
    production_year BETWEEN 2010 AND 2020
ORDER BY 
    keyword_used;
