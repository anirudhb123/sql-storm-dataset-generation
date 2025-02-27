WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
CompanyCounts AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT c.id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    GROUP BY 
        mc.movie_id
),
CastRoles AS (
    SELECT 
        c.movie_id,
        r.role,
        COUNT(c.id) AS role_count
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.movie_id, r.role
),
FinalResult AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        COALESCE(cc.company_count, 0) AS company_count,
        COALESCE(SUM(cr.role_count), 0) AS total_roles
    FROM 
        RankedMovies rm
    LEFT JOIN 
        CompanyCounts cc ON rm.movie_id = cc.movie_id
    LEFT JOIN 
        CastRoles cr ON rm.movie_id = cr.movie_id
    GROUP BY 
        rm.movie_id, rm.title, rm.production_year, cc.company_count
)

SELECT 
    fr.movie_id,
    fr.title,
    fr.production_year,
    fr.company_count,
    fr.total_roles,
    CASE 
        WHEN fr.total_roles > 10 THEN 'High Role Count'
        WHEN fr.total_roles >= 5 THEN 'Medium Role Count'
        ELSE 'Low Role Count' 
    END AS role_count_category
FROM 
    FinalResult fr
ORDER BY 
    fr.production_year DESC, 
    fr.title ASC;
