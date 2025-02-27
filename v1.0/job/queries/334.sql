WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id, 
        t.title, 
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank
    FROM title t
    WHERE t.production_year IS NOT NULL
), 
ActorsWithRoles AS (
    SELECT 
        a.id AS actor_id,
        a.name,
        c.movie_id,
        r.role 
    FROM aka_name a
    JOIN cast_info c ON a.person_id = c.person_id
    JOIN role_type r ON c.role_id = r.id
), 
MovieCompanies AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
        STRING_AGG(DISTINCT ct.kind, ', ') AS company_types
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    JOIN company_type ct ON mc.company_type_id = ct.id 
    GROUP BY mc.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    COALESCE(a.name, 'Unknown Actor') AS actor_name,
    COALESCE(a.role, 'No Role') AS role,
    mc.company_names,
    mc.company_types
FROM RankedMovies rm
LEFT JOIN ActorsWithRoles a ON rm.movie_id = a.movie_id
LEFT JOIN MovieCompanies mc ON rm.movie_id = mc.movie_id
WHERE 
    (rm.rank <= 5 OR (rm.production_year IS NULL AND rm.movie_id IS NOT NULL))
ORDER BY 
    rm.production_year DESC, 
    rm.title ASC, 
    actor_name NULLS LAST;
