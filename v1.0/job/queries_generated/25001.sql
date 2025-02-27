WITH movie_data AS (
    SELECT 
        mt.title AS movie_title,
        mt.production_year,
        ak.name AS actor_name,
        rt.role AS actor_role,
        ct.kind AS company_type,
        rn.name AS production_company
    FROM 
        aka_title mt
    JOIN 
        cast_info ci ON mt.id = ci.movie_id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    JOIN 
        role_type rt ON ci.role_id = rt.id
    JOIN 
        movie_companies mc ON mt.id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    JOIN 
        name rn ON cn.id = rn.imdb_id
    WHERE 
        mt.production_year > 2000
        AND ak.name LIKE '%Smith%'
)

SELECT 
    movie_title,
    production_year,
    STRING_AGG(DISTINCT actor_name, ', ') AS actors,
    STRING_AGG(DISTINCT actor_role, ', ') AS roles,
    STRING_AGG(DISTINCT company_type, ', ') AS production_types,
    STRING_AGG(DISTINCT production_company, ', ') AS production_companies
FROM 
    movie_data
GROUP BY 
    movie_title, production_year
ORDER BY 
    production_year DESC, 
    movie_title;
