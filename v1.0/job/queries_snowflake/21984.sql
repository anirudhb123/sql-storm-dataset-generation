
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorRoles AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        rt.role AS role,
        RANK() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS actor_rank
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type rt ON c.role_id = rt.id
    WHERE 
        c.note IS NULL 
        AND a.name IS NOT NULL
),
MovieCompanies AS (
    SELECT 
        mc.movie_id, 
        cn.name AS company_name, 
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
FilteredMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        COUNT(DISTINCT ac.actor_name) AS actor_count,
        LISTAGG(DISTINCT mc.company_name, ', ') WITHIN GROUP (ORDER BY mc.company_name) AS companies
    FROM 
        RankedMovies rm
    LEFT JOIN 
        ActorRoles ac ON rm.movie_id = ac.movie_id
    LEFT JOIN 
        MovieCompanies mc ON rm.movie_id = mc.movie_id
    WHERE 
        rm.year_rank <= 5 
        AND rm.title LIKE '%Adventure%' 
    GROUP BY 
        rm.movie_id, rm.title
)
SELECT 
    fm.movie_id,
    fm.title,
    fm.actor_count,
    fm.companies,
    CASE 
        WHEN fm.actor_count > 5 THEN 'Popular'
        WHEN fm.actor_count IS NULL THEN 'Unknown'
        ELSE 'Lesser-known'
    END AS movie_type,
    COALESCE(NULLIF(fm.companies, ''), 'Independent') AS company_info
FROM 
    FilteredMovies fm
WHERE 
    fm.actor_count IS NOT NULL
ORDER BY 
    fm.actor_count DESC, 
    fm.title ASC;
