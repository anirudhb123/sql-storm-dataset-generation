WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) AS rank_by_year
    FROM 
        aka_title a
    WHERE 
        a.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
),
ActorRoles AS (
    SELECT 
        ci.movie_id,
        ak.name AS actor_name,
        rt.role,
        coalesce(MAX(ci.nr_order), 0) AS max_order
    FROM 
        cast_info ci
    JOIN aka_name ak ON ci.person_id = ak.person_id
    JOIN role_type rt ON ci.role_id = rt.id
    GROUP BY 
        ci.movie_id, ak.name, rt.role
),
CompanyUsage AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT cn.name) AS company_count,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names
    FROM 
        movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    ar.actor_name,
    ar.role,
    cu.company_count,
    cu.company_names,
    CASE 
        WHEN rm.rank_by_year <= 3 THEN 'Top Release of the Year'
        ELSE 'Regular Release'
    END AS release_category
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorRoles ar ON rm.movie_id = ar.movie_id
LEFT JOIN 
    CompanyUsage cu ON rm.movie_id = cu.movie_id
WHERE 
    rm.production_year IS NOT NULL
ORDER BY 
    rm.production_year DESC, rm.title;
