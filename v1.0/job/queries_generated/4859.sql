WITH movie_details AS (
    SELECT 
        a.title AS movie_title,
        COUNT(DISTINCT c.person_id) AS total_cast,
        AVG(CASE WHEN r.role IS NOT NULL THEN 1 ELSE 0 END) AS avg_has_role,
        MAX(t.production_year) AS latest_production_year
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    LEFT JOIN 
        role_type r ON c.role_id = r.id
    JOIN 
        title t ON a.movie_id = t.id
    WHERE 
        a.production_year IS NOT NULL
    GROUP BY 
        a.title
),
company_details AS (
    SELECT 
        m.movie_id,
        GROUP_CONCAT(DISTINCT cn.name) AS companies_involved,
        COUNT(DISTINCT mc.company_id) AS num_companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        aka_title m ON mc.movie_id = m.id
    GROUP BY 
        m.movie_id
)
SELECT 
    md.movie_title,
    md.total_cast,
    md.avg_has_role,
    md.latest_production_year,
    COALESCE(cd.companies_involved, 'No Companies') AS companies_involved,
    COALESCE(cd.num_companies, 0) AS num_companies
FROM 
    movie_details md
LEFT JOIN 
    company_details cd ON md.movie_title = cd.movie_id
ORDER BY 
    md.latest_production_year DESC,
    md.total_cast DESC
LIMIT 10
OFFSET 5;
