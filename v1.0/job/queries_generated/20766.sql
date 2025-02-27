WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.production_year DESC, m.title ASC) AS year_rank,
        COUNT(cm.company_id) OVER (PARTITION BY m.id) AS company_count
    FROM 
        aka_title m
    LEFT JOIN 
        movie_companies cm ON m.id = cm.movie_id
    WHERE 
        m.production_year IS NOT NULL
),
ActorRoles AS (
    SELECT 
        a.name,
        r.role,
        c.movie_id,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY c.nr_order ASC) AS role_order
    FROM 
        aka_name a
    INNER JOIN 
        cast_info c ON a.person_id = c.person_id
    LEFT JOIN 
        role_type r ON c.role_id = r.id
),
CompanyTypes AS (
    SELECT 
        ct.kind AS company_type
    FROM 
        company_type ct
    WHERE 
        ct.kind ILIKE '%Production%' OR ct.kind ILIKE '%Pictures%'
),
FilteredMovies AS (
    SELECT 
        rm.movie_id, 
        rm.title, 
        rm.production_year,
        ar.name AS actor_name,
        ar.role,
        ar.role_order,
        CASE 
            WHEN rm.company_count > 0 THEN 'Has Companies'
            ELSE 'No Companies'
        END AS company_status,
        COALESCE(ct.company_type, 'Unknown') AS company_group
    FROM 
        RankedMovies rm
    LEFT JOIN 
        ActorRoles ar ON rm.movie_id = ar.movie_id
    LEFT JOIN 
        movie_companies mc ON rm.movie_id = mc.movie_id
    LEFT JOIN 
        CompanyTypes ct ON mc.company_type_id = ct.id
)
SELECT 
    f.title,
    f.production_year,
    f.actor_name,
    f.role,
    f.company_status,
    COUNT(*) AS role_count,
    STRING_AGG(DISTINCT f.actor_name, ', ') AS all_actors
FROM 
    FilteredMovies f
WHERE 
    f.company_status IS NOT NULL 
    AND f.production_year > 2000
GROUP BY 
    f.title, f.production_year, f.actor_name, f.role, f.company_status
HAVING 
    COUNT(f.role) > 1 OR MAX(f.role_order) > 1
ORDER BY 
    f.production_year DESC, 
    COUNT(*) DESC, 
    f.title ASC
FETCH FIRST 50 ROWS ONLY;
