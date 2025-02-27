WITH movie_titles AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.kind_id,
        k.keyword
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year >= 2000 
        AND k.keyword ILIKE '%Action%'
),
person_roles AS (
    SELECT 
        ci.movie_id,
        p.name AS actor_name,
        rt.role AS role_name
    FROM 
        cast_info ci
    JOIN 
        aka_name p ON ci.person_id = p.person_id
    JOIN 
        role_type rt ON ci.role_id = rt.id
    WHERE 
        rt.role IN ('Actor', 'Director')
),
company_details AS (
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
        c.country_code = 'USA'
),
info_summary AS (
    SELECT 
        mi.movie_id,
        STRING_AGG(mi.info, '; ') AS additional_info
    FROM 
        movie_info mi
    GROUP BY 
        mi.movie_id
)
SELECT 
    mt.movie_id,
    mt.title,
    mt.production_year,
    mt.kind_id,
    STRING_AGG(DISTINCT pr.actor_name, ', ') AS actors,
    STRING_AGG(DISTINCT pr.role_name, ', ') AS roles,
    STRING_AGG(DISTINCT cd.company_name || ' (' || cd.company_type || ')', '; ') AS companies,
    COALESCE(is.summary_info, 'No additional info') AS additional_info
FROM 
    movie_titles mt
LEFT JOIN 
    person_roles pr ON mt.movie_id = pr.movie_id
LEFT JOIN 
    company_details cd ON mt.movie_id = cd.movie_id
LEFT JOIN 
    info_summary is ON mt.movie_id = is.movie_id
GROUP BY 
    mt.movie_id, mt.title, mt.production_year, mt.kind_id
ORDER BY 
    mt.production_year DESC, mt.title;
