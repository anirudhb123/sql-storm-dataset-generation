
WITH movie_title AS (
    SELECT 
        t.id AS title_id, 
        t.title,
        t.production_year,
        k.keyword
    FROM 
        aka_title t 
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year >= 2000
),
person_cast AS (
    SELECT 
        ci.movie_id,
        a.name AS actor_name,
        r.role AS role_name
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        role_type r ON ci.role_id = r.id
),
company_info AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    WHERE 
        ct.kind = 'Production'
),
full_info AS (
    SELECT 
        mt.title_id,
        mt.title,
        mt.production_year,
        pc.actor_name,
        pc.role_name,
        ci.company_name,
        ci.company_type,
        mt.keyword
    FROM 
        movie_title mt
    LEFT JOIN 
        person_cast pc ON mt.title_id = pc.movie_id
    LEFT JOIN 
        company_info ci ON mt.title_id = ci.movie_id
)
SELECT 
    title_id,
    title,
    production_year,
    LISTAGG(DISTINCT actor_name, ', ') WITHIN GROUP (ORDER BY actor_name) AS actors,
    LISTAGG(DISTINCT role_name, ', ') WITHIN GROUP (ORDER BY role_name) AS roles,
    LISTAGG(DISTINCT company_name, ', ') WITHIN GROUP (ORDER BY company_name) AS production_companies,
    LISTAGG(DISTINCT company_type, ', ') WITHIN GROUP (ORDER BY company_type) AS production_types,
    LISTAGG(DISTINCT keyword, ', ') WITHIN GROUP (ORDER BY keyword) AS keywords
FROM 
    full_info
GROUP BY 
    title_id, title, production_year
ORDER BY 
    production_year DESC, title;
