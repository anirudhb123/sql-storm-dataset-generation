WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rn,
        COUNT(*) OVER (PARTITION BY t.production_year) AS total_movies
    FROM title t
    WHERE t.production_year BETWEEN 2000 AND 2023
),

FilteredTitles AS (
    SELECT 
        rm.title_id,
        rm.title,
        rm.production_year,
        CASE 
            WHEN rm.rn = 1 THEN 'First'
            WHEN rm.rn = total_movies THEN 'Last'
            ELSE 'Middle'
        END AS position
    FROM RankedMovies rm
),

ActorRoles AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT cr.role_id) AS role_count,
        STRING_AGG(DISTINCT CONCAT(a.name, ' as ', rt.role), ', ') AS actor_roles
    FROM cast_info c
    JOIN aka_name a ON c.person_id = a.person_id
    JOIN role_type rt ON c.role_id = rt.id
    GROUP BY c.movie_id
),

CompanyData AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type,
        ROW_NUMBER() OVER (PARTITION BY mc.movie_id ORDER BY cn.name) AS company_rank
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    JOIN company_type ct ON mc.company_type_id = ct.id
),

FinalResults AS (
    SELECT 
        ft.title_id,
        ft.title,
        ft.production_year,
        ft.position,
        ar.role_count,
        ar.actor_roles,
        cd.company_name,
        cd.company_type,
        cd.company_rank
    FROM FilteredTitles ft
    LEFT JOIN ActorRoles ar ON ft.title_id = ar.movie_id
    LEFT JOIN CompanyData cd ON ft.title_id = cd.movie_id
    WHERE cd.company_rank = 1 OR cd.company_rank IS NULL
)

SELECT 
    fr.title,
    fr.production_year,
    fr.position,
    COALESCE(fr.role_count, 0) AS role_count,
    COALESCE(fr.actor_roles, 'No Roles Assigned') AS actor_roles,
    COALESCE(fr.company_name, 'Independent') AS company_name,
    COALESCE(fr.company_type, 'N/A') AS company_type
FROM FinalResults fr
ORDER BY fr.production_year DESC, fr.title;
