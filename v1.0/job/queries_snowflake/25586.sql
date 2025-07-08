WITH movie_title_info AS (
    SELECT 
        t.id AS movie_id, 
        t.title AS movie_title, 
        t.production_year, 
        k.keyword AS movie_keyword,
        rt.role AS actor_role,
        a.name AS actor_name
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        role_type rt ON ci.role_id = rt.id
    WHERE 
        t.production_year >= 2000
),
company_info AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        mc.note AS company_note
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    WHERE 
        c.country_code = 'USA'
),
full_movie_details AS (
    SELECT 
        mt.movie_id,
        mt.movie_title,
        mt.production_year,
        mt.movie_keyword,
        mt.actor_role,
        mt.actor_name,
        ci.company_name,
        ci.company_type,
        ci.company_note
    FROM 
        movie_title_info mt
    LEFT JOIN 
        company_info ci ON mt.movie_id = ci.movie_id
)
SELECT 
    fmd.movie_title,
    fmd.production_year,
    fmd.movie_keyword,
    fmd.actor_role,
    fmd.actor_name,
    ARRAY_AGG(DISTINCT fmd.company_name) AS companies,
    ARRAY_AGG(DISTINCT fmd.company_type) AS company_types,
    COUNT(fmd.company_name) AS company_count
FROM 
    full_movie_details fmd
GROUP BY 
    fmd.movie_title, 
    fmd.production_year, 
    fmd.movie_keyword, 
    fmd.actor_role, 
    fmd.actor_name
ORDER BY 
    fmd.production_year DESC, 
    fmd.movie_title;
