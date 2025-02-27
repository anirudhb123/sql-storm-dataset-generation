WITH RankedTitles AS (
    SELECT 
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
RoleStats AS (
    SELECT 
        ci.person_id,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        COUNT(DISTINCT r.role) AS role_count
    FROM 
        cast_info ci
    JOIN 
        role_type r ON ci.role_id = r.id
    GROUP BY 
        ci.person_id
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        COUNT(DISTINCT m.id) AS related_movies
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    LEFT JOIN 
        movie_info m ON mc.movie_id = m.movie_id
    GROUP BY 
        mc.movie_id, c.name, ct.kind
)
SELECT 
    rt.title,
    rt.production_year,
    COALESCE(rs.movie_count, 0) AS total_movies,
    COALESCE(rs.role_count, 0) AS unique_roles,
    ci.company_name,
    ci.company_type,
    ci.related_movies
FROM 
    RankedTitles rt
LEFT JOIN 
    RoleStats rs ON rt.production_year = rs.movie_count
LEFT JOIN 
    CompanyInfo ci ON rt.production_year = ci.movie_id
WHERE 
    rt.year_rank = 1
ORDER BY 
    rt.production_year DESC, total_movies DESC;
