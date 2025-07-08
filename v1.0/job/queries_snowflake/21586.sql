
WITH MovieRoleCounts AS (
    SELECT 
        a.title,
        COUNT(DISTINCT c.person_id) AS role_count,
        AVG(CASE WHEN c.note IS NOT NULL THEN 1 ELSE 0 END) AS has_note_ratio
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.movie_id = c.movie_id
    GROUP BY 
        a.title
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        LISTAGG(DISTINCT cn.name, ', ') WITHIN GROUP (ORDER BY cn.name) AS companies,
        MAX(ct.kind) AS main_company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
),
MovieDetails AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COALESCE(mr.role_count, 0) AS number_of_roles,
        ci.companies,
        ci.main_company_type
    FROM 
        aka_title m
    LEFT JOIN 
        MovieRoleCounts mr ON m.title = mr.title
    LEFT JOIN 
        CompanyInfo ci ON m.id = ci.movie_id
)
SELECT 
    md.title,
    md.production_year,
    md.number_of_roles,
    md.companies,
    md.main_company_type,
    COALESCE(md.number_of_roles, 0) AS adjusted_roles,
    CASE 
        WHEN md.number_of_roles IS NULL THEN 'No roles available'
        WHEN md.number_of_roles > 10 THEN 'Highly Casted'
        ELSE 'Moderate Casted'
    END AS casting_category,
    SUM(CASE 
        WHEN LOWER(md.title) LIKE '%love%' THEN 1 
        ELSE 0 
    END) OVER () AS love_movie_count,
    COUNT(*) OVER (PARTITION BY md.production_year) AS movies_per_year
FROM 
    MovieDetails md
WHERE 
    md.production_year IS NOT NULL
ORDER BY 
    md.production_year DESC, 
    md.number_of_roles DESC 
LIMIT 100;
