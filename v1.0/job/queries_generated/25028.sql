WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        ARRAY_AGG(DISTINCT ak.name) AS aka_names
    FROM 
        aka_title ak
    JOIN 
        title mt ON ak.movie_id = mt.id
    JOIN 
        cast_info ci ON mt.id = ci.movie_id
    GROUP BY 
        mt.id
),
PopularRoles AS (
    SELECT 
        role.role AS role_name,
        COUNT(DISTINCT ci.person_id) AS role_frequency
    FROM 
        cast_info ci
    JOIN 
        role_type role ON ci.role_id = role.id
    GROUP BY 
        role.role
    HAVING 
        COUNT(DISTINCT ci.person_id) > 5
),
MovieCompanies AS (
    SELECT 
        mc.movie_id,
        GROUP_CONCAT(DISTINCT cn.name ORDER BY cn.name) AS company_names,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)

SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.total_cast,
    rm.aka_names,
    mc.company_names,
    mc.company_count,
    pr.role_name,
    pr.role_frequency
FROM 
    RankedMovies rm
LEFT JOIN 
    MovieCompanies mc ON rm.movie_id = mc.movie_id
LEFT JOIN 
    PopularRoles pr ON pr.role_frequency >= 3
ORDER BY 
    rm.total_cast DESC, 
    rm.production_year DESC;
