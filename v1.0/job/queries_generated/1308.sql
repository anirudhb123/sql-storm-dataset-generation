WITH ranked_movies AS (
    SELECT 
        at.title,
        at.production_year,
        COUNT(DISTINCT mc.company_id) AS company_count,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(DISTINCT mc.company_id) DESC) AS rank
    FROM 
        aka_title at
    LEFT JOIN 
        movie_companies mc ON at.id = mc.movie_id
    GROUP BY 
        at.id, at.title, at.production_year
),
average_role_count AS (
    SELECT 
        ci.movie_id,
        AVG(role_count) AS average_roles
    FROM (
        SELECT 
            ci.movie_id,
            COUNT(DISTINCT ci.role_id) AS role_count
        FROM 
            cast_info ci
        GROUP BY 
            ci.movie_id
    ) AS role_counts
    GROUP BY 
        movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    rm.company_count,
    COALESCE(ar.average_roles, 0) AS average_roles,
    CASE 
        WHEN rm.company_count IS NULL THEN 'No Companies'
        WHEN rm.company_count > 5 THEN 'Many Companies'
        ELSE 'Few Companies'
    END AS company_category
FROM 
    ranked_movies rm
LEFT JOIN 
    average_role_count ar ON rm.id = ar.movie_id
WHERE 
    rm.rank = 1
ORDER BY 
    rm.production_year DESC, rm.company_count DESC;
