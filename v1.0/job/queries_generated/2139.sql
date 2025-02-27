WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
MovieRoles AS (
    SELECT 
        c.movie_id,
        r.role AS role,
        COUNT(c.person_id) AS actor_count
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.movie_id, r.role
),
MovieCompanies AS (
    SELECT 
        mc.movie_id,
        comp.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name comp ON mc.company_id = comp.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
FilteredMovies AS (
    SELECT 
        rm.title_id,
        rm.title,
        rm.production_year,
        COALESCE(mr.actor_count, 0) AS actor_count,
        COALESCE(SUM(mc.company_name)::text, 'No Companies') AS companies
    FROM 
        RankedMovies rm
    LEFT JOIN 
        MovieRoles mr ON rm.title_id = mr.movie_id
    LEFT JOIN 
        MovieCompanies mc ON rm.title_id = mc.movie_id
    WHERE 
        rm.year_rank <= 10
    GROUP BY 
        rm.title_id, rm.title, rm.production_year, mr.actor_count
)
SELECT 
    fm.title,
    fm.production_year,
    fm.actor_count,
    fm.companies
FROM 
    FilteredMovies fm
WHERE 
    fm.actor_count > 2
ORDER BY 
    fm.production_year DESC, fm.title;
