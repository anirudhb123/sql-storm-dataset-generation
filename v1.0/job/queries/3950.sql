
WITH movie_details AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords,
        COUNT(DISTINCT mc.company_id) AS production_companies
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    GROUP BY 
        m.id, m.title, m.production_year
),
actor_performance AS (
    SELECT 
        ci.movie_id,
        a.name AS actor_name,
        COUNT(ci.person_id) AS role_count,
        SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS noted_roles,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY COUNT(ci.person_id) DESC) AS rn
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    GROUP BY 
        ci.movie_id, a.name
),
final_output AS (
    SELECT 
        md.title,
        md.production_year,
        md.keywords,
        md.production_companies,
        ap.actor_name,
        ap.role_count,
        ap.noted_roles,
        ap.rn
    FROM 
        movie_details md
    LEFT JOIN 
        actor_performance ap ON md.movie_id = ap.movie_id
    WHERE 
        md.production_year >= 2000
        AND md.production_companies > 0
        AND (ap.role_count > 2 OR ap.noted_roles > 1)
)
SELECT 
    fo.title,
    fo.production_year,
    fo.keywords,
    fo.actor_name,
    fo.role_count,
    fo.noted_roles
FROM 
    final_output fo
WHERE 
    fo.rn IS NULL OR fo.rn <= 3
ORDER BY 
    fo.production_year DESC, 
    fo.role_count DESC
LIMIT 50;
