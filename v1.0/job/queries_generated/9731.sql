WITH movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        c.kind AS company_type,
        k.keyword,
        ak.name AS actor_name,
        pi.info AS person_info
    FROM 
        title t
    JOIN 
        movie_info mi ON t.id = mi.movie_id
    JOIN 
        kind_type kt ON t.kind_id = kt.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        company_type c ON mc.company_type_id = c.id
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        person_info pi ON ak.person_id = pi.person_id
    WHERE 
        mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Plot')
    ORDER BY 
        t.production_year DESC
)
SELECT 
    movie_id,
    title,
    production_year,
    company_type,
    STRING_AGG(DISTINCT keyword, ', ') AS keywords,
    STRING_AGG(DISTINCT actor_name, ', ') AS actors,
    STRING_AGG(DISTINCT person_info, ', ') AS personal_info
FROM 
    movie_details
GROUP BY 
    movie_id, title, production_year, company_type
HAVING 
    production_year >= 2000
ORDER BY 
    production_year DESC, title;
