WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.season_nr DESC, t.episode_nr DESC) AS rn
    FROM 
        aka_title t
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('movie', 'tv series'))
),
FilteredMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year
    FROM 
        RankedMovies rm
    WHERE 
        rm.rn <= 5
),
MovieCompanyInfo AS (
    SELECT 
        mc.movie_id,
        ARRAY_AGG(DISTINCT cn.name) AS company_names,
        ARRAY_AGG(DISTINCT ct.kind) AS company_types
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
),
ActorRoleCount AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        SUM(CASE WHEN ci.person_role_id IS NOT NULL THEN 1 ELSE 0 END) AS role_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
)
SELECT 
    fm.title,
    fm.production_year,
    COALESCE(mci.company_names, '{}') AS company_names,
    COALESCE(mci.company_types, '{}') AS company_types,
    COALESCE(arc.actor_count, 0) AS actor_count,
    CASE 
        WHEN COALESCE(arc.role_count, 0) = 0 THEN 'No roles assigned'
        WHEN COALESCE(arc.actor_count, 0) > 10 THEN 'Many actors'
        ELSE 'Few actors'
    END AS role_description
FROM 
    FilteredMovies fm
LEFT JOIN 
    MovieCompanyInfo mci ON fm.movie_id = mci.movie_id
LEFT JOIN 
    ActorRoleCount arc ON fm.movie_id = arc.movie_id
ORDER BY 
    fm.production_year DESC, 
    fm.title ASC
LIMIT 50;
