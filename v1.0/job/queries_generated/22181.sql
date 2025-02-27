WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id, 
        t.title, 
        t.production_year, 
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, LENGTH(t.title) DESC) AS rank_by_year
    FROM 
        aka_title t
    WHERE
        t.production_year IS NOT NULL
),
FilteredNames AS (
    SELECT 
        a.person_id, 
        a.name, 
        a.md5sum, 
        COALESCE(c.id, 0) AS cast_info_id
    FROM 
        aka_name a
    LEFT JOIN 
        cast_info c ON a.person_id = c.person_id
    WHERE 
        a.name IS NOT NULL AND 
        a.name NOT LIKE '%[^A-Za-z0-9]%'  -- Filter out names with special characters
),
MovieCompanies AS (
    SELECT 
        mc.movie_id, 
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        movie_companies mc
    GROUP BY 
        mc.movie_id
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
    GROUP BY 
        ci.movie_id, 
        rt.role
),
CombinedData AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        fn.name AS person_name,
        rc.role,
        CASE 
            WHEN rc.role IS NOT NULL THEN rc.role_count 
            ELSE 0 
        END AS total_roles,
        cm.company_count
    FROM 
        RankedMovies rm
    LEFT JOIN 
        FilteredNames fn ON fn.cast_info_id = rm.movie_id
    LEFT JOIN 
        CastRoles rc ON rc.movie_id = rm.movie_id
    LEFT JOIN 
        MovieCompanies cm ON cm.movie_id = rm.movie_id
)
SELECT 
    cd.title,
    cd.production_year,
    cd.person_name,
    cd.role,
    cd.total_roles,
    cd.company_count,
    CASE 
        WHEN cd.company_count > 5 THEN 'Highly produced'
        WHEN cd.company_count IS NULL THEN 'No companies'
        ELSE 'Moderately produced' 
    END AS production_description
FROM 
    CombinedData cd
WHERE 
    cd.rank_by_year <= 5 AND 
    (cd.person_name IS NOT NULL OR cd.role IS NULL)
ORDER BY 
    cd.production_year DESC, 
    cd.company_count DESC NULLS LAST;
