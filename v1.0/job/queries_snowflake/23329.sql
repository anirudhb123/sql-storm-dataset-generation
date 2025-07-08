
WITH RecursiveMovieTitles AS (
    SELECT 
        t.id AS title_id,
        t.title AS title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rn
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
CastRoles AS (
    SELECT 
        ci.movie_id,
        ci.person_id,
        COALESCE(rt.role, 'Unknown Role') AS role,
        COUNT(*) OVER (PARTITION BY ci.movie_id) AS total_roles
    FROM 
        cast_info ci
    LEFT JOIN 
        role_type rt ON ci.role_id = rt.id
),
CompanyMovieInfo AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_kind,
        COUNT(*) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id, c.name, ct.kind
),
FilteredMovies AS (
    SELECT 
        mt.title, 
        mt.production_year,
        LISTAGG(DISTINCT cm.company_name || ' (' || cm.company_kind || ')', ', ') WITHIN GROUP (ORDER BY cm.company_name) AS company_info,
        COUNT(DISTINCT cr.person_id) AS unique_cast_count,
        SUM(CASE WHEN cr.role <> 'Unknown Role' THEN cr.total_roles ELSE 0 END) AS known_role_count
    FROM 
        RecursiveMovieTitles mt
    LEFT JOIN 
        CastRoles cr ON mt.title_id = cr.movie_id
    LEFT JOIN 
        CompanyMovieInfo cm ON mt.title_id = cm.movie_id
    WHERE 
        mt.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        mt.title, mt.production_year
)
SELECT 
    title, 
    production_year, 
    company_info,
    unique_cast_count,
    known_role_count,
    CASE 
        WHEN unique_cast_count IS NULL THEN 'No Cast Data'
        WHEN unique_cast_count > 50 THEN 'Blockbuster'
        WHEN known_role_count / NULLIF(unique_cast_count, 0) < 0.5 THEN 'High Unknown Roles'
        ELSE 'Standard Movie'
    END AS movie_category
FROM 
    FilteredMovies
ORDER BY 
    production_year DESC, 
    title;
