WITH movie_details AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        GROUP_CONCAT(DISTINCT ak.name ORDER BY ak.name SEPARATOR ', ') AS actor_names,
        GROUP_CONCAT(DISTINCT kw.keyword ORDER BY kw.keyword SEPARATOR ', ') AS keywords,
        ckt.kind AS company_type,
        ct.kind AS role_type
    FROM 
        title t
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        company_type ct ON mc.company_type_id = ct.id
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    LEFT JOIN 
        role_type ckt ON ci.role_id = ckt.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        t.id, t.title, t.production_year, ckt.kind, ct.kind
) 

SELECT 
    md.movie_title,
    md.production_year,
    md.actor_names,
    md.keywords,
    COUNT(DISTINCT md.company_type) AS distinct_company_types,
    COUNT(DISTINCT md.role_type) AS distinct_roles
FROM 
    movie_details md
GROUP BY 
    md.movie_title, 
    md.production_year, 
    md.actor_names,
    md.keywords
ORDER BY 
    md.production_year DESC, 
    md.movie_title ASC
LIMIT 10;
