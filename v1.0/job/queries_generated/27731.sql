WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT kc.id) AS keyword_count,
        COALESCE(SUM(mk.note IS NOT NULL)::int, 0) AS additional_info_count
    FROM 
        title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword kc ON mk.keyword_id = kc.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023 
    GROUP BY 
        t.id, t.title, t.production_year
),
cast_roles AS (
    SELECT 
        ci.movie_id,
        ARRAY_AGG(DISTINCT r.role ORDER BY r.role) AS roles,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM 
        cast_info ci
    JOIN 
        role_type r ON ci.person_role_id = r.id
    GROUP BY 
        ci.movie_id
),
company_details AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        COUNT(DISTINCT mc.id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id, c.name, ct.kind
)
SELECT 
    rt.title,
    rt.production_year,
    rt.keyword_count,
    rt.additional_info_count,
    cr.roles,
    cr.actor_count,
    cd.company_name,
    cd.company_type,
    cd.company_count
FROM 
    ranked_titles rt
LEFT JOIN 
    cast_roles cr ON rt.title_id = cr.movie_id
LEFT JOIN 
    company_details cd ON rt.title_id = cd.movie_id
ORDER BY 
    rt.production_year DESC, rt.keyword_count DESC, cr.actor_count DESC;
