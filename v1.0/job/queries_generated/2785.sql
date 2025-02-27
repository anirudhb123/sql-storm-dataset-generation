WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rn
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
MovieRoles AS (
    SELECT 
        c.movie_id,
        r.role,
        COUNT(c.person_id) AS role_count
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.movie_id, r.role
),
MovieCompaniesWithRoles AS (
    SELECT 
        mc.movie_id,
        co.name AS company_name,
        mr.role,
        mr.role_count
    FROM 
        movie_companies mc
    LEFT JOIN 
        company_name co ON mc.company_id = co.id
    LEFT JOIN 
        MovieRoles mr ON mc.movie_id = mr.movie_id
),
FinalResults AS (
    SELECT 
        m.title,
        m.production_year,
        COALESCE(c.role, 'Unknown Role') AS role,
        mcr.company_name,
        mcr.role_count
    FROM 
        RankedMovies m
    LEFT JOIN 
        MovieCompaniesWithRoles mcr ON m.title_id = mcr.movie_id
    LEFT JOIN 
        (SELECT movie_id, role FROM MovieRoles WHERE role_count > 1) c ON m.title_id = c.movie_id
)
SELECT 
    fr.title,
    fr.production_year,
    fr.role,
    fr.company_name,
    fr.role_count,
    (CASE 
        WHEN fr.role_count IS NULL THEN 'No roles'
        ELSE CAST(fr.role_count AS TEXT) || ' roles'
    END) AS role_description
FROM 
    FinalResults fr
WHERE 
    fr.production_year BETWEEN 2000 AND 2020
ORDER BY 
    fr.production_year DESC, fr.title;
