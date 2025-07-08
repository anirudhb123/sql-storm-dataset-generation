
WITH RankedMovies AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        ROLES.role AS movie_role,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY a.production_year DESC) AS rank_order,
        a.id
    FROM 
        aka_title a
    JOIN 
        cast_info c ON a.id = c.movie_id
    JOIN 
        role_type ROLES ON c.role_id = ROLES.id
    WHERE 
        a.production_year IS NOT NULL
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        LISTAGG(DISTINCT cn.name, ', ') WITHIN GROUP (ORDER BY cn.name) AS company_names,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    rm.movie_title,
    rm.production_year,
    rm.movie_role,
    ci.company_names,
    ci.company_count
FROM 
    RankedMovies rm
LEFT JOIN 
    CompanyInfo ci ON rm.id = ci.movie_id
WHERE 
    rm.rank_order = 1
    AND (ci.company_count > 2 OR ci.company_names IS NULL)
ORDER BY 
    rm.production_year DESC,
    rm.movie_title ASC;
