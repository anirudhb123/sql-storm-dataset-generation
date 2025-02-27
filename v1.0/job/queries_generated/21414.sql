WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),

ActorRoles AS (
    SELECT 
        ci.person_id,
        ci.movie_id,
        COUNT(DISTINCT ci.role_id) AS role_count,
        STRING_AGG(DISTINCT rt.role, ', ') AS roles
    FROM 
        cast_info ci
    LEFT JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        ci.person_id, ci.movie_id
),

CompanyMovieLinks AS (
    SELECT 
        mc.movie_id,
        ARRAY_AGG(DISTINCT cn.name) AS company_names
    FROM 
        movie_companies mc
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),

MoviesWithActors AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        ar.person_id,
        ar.role_count,
        ar.roles,
        cml.company_names
    FROM 
        RankedMovies rm
    LEFT JOIN 
        ActorRoles ar ON rm.movie_id = ar.movie_id
    LEFT JOIN 
        CompanyMovieLinks cml ON rm.movie_id = cml.movie_id
)

SELECT 
    mw.title,
    mw.production_year,
    mw.roles,
    mw.company_names,
    CASE 
        WHEN mw.role_count IS NULL THEN 'No Roles'
        WHEN mw.role_count > 5 THEN 'Versatile Actor'
        ELSE 'Niche Actor'
    END AS actor_category,
    COALESCE(SUM(CASE WHEN mw.roles IS NOT NULL THEN 1 ELSE 0 END), 0) AS total_actors_with_roles
FROM 
    MoviesWithActors mw
LEFT JOIN 
    aka_name an ON mw.person_id = an.person_id
WHERE 
    mw.production_year >= 2000 AND 
    (LEFT(mw.title, 1) IN ('A', 'B', 'C') OR mw.title_rank <= 3)
GROUP BY 
    mw.title, mw.production_year, mw.roles, mw.company_names, mw.role_count
ORDER BY 
    mw.production_year DESC, 
    mw.title;
