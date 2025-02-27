WITH RankedMovies AS (
    SELECT 
        at.id AS title_id,
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.id) AS rn
    FROM 
        aka_title at
    WHERE 
        at.production_year IS NOT NULL
),
CastRoles AS (
    SELECT 
        ci.movie_id,
        rt.role,
        COUNT(*) AS role_count
    FROM 
        cast_info ci
    JOIN 
        role_type rt ON ci.role_id = rt.id
    WHERE 
        rt.role IS NOT NULL
    GROUP BY 
        ci.movie_id, rt.role
),
PopularKeywords AS (
    SELECT
        mk.movie_id,
        k.keyword,
        COUNT(*) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        k.keyword IS NOT NULL
    GROUP BY 
        mk.movie_id, k.keyword
),
MovieCompanies AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        movie_companies mc
    WHERE 
        mc.company_type_id IS NOT NULL
    GROUP BY 
        mc.movie_id
),
OuterJoinMovies AS (
    SELECT 
        rm.title_id,
        rm.title,
        rm.production_year,
        COALESCE(cr.role_count, 0) AS total_roles,
        COALESCE(pk.keyword_count, 0) AS keyword_count,
        COALESCE(mc.company_count, 0) AS company_count
    FROM 
        RankedMovies rm
    LEFT JOIN 
        CastRoles cr ON rm.title_id = cr.movie_id
    LEFT JOIN 
        PopularKeywords pk ON rm.title_id = pk.movie_id
    LEFT JOIN 
        MovieCompanies mc ON rm.title_id = mc.movie_id
)
SELECT 
    om.title,
    om.production_year,
    om.total_roles,
    om.keyword_count,
    om.company_count,
    CASE 
        WHEN om.total_roles > 5 THEN 'High Role Count'
        WHEN om.total_roles BETWEEN 3 AND 5 THEN 'Medium Role Count'
        ELSE 'Low Role Count'
    END AS role_category,
    CONCAT('Title: ', om.title, ' (', om.production_year, ')') AS title_description
FROM 
    OuterJoinMovies om
WHERE 
    om.production_year IN (SELECT DISTINCT production_year FROM RankedMovies WHERE rn = 1)
    AND (om.keyword_count > 0 OR om.company_count IS NULL)
ORDER BY 
    om.production_year DESC,
    om.total_roles DESC;
