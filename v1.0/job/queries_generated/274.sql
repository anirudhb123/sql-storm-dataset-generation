WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.title) AS rank
    FROM 
        title m
    WHERE 
        m.kind_id IN (SELECT id FROM kind_type WHERE kind ILIKE '%drama%')
),
ActorStats AS (
    SELECT 
        a.person_id,
        COUNT(DISTINCT c.movie_id) AS movie_count,
        AVG(COALESCE(ci.nr_order, 0)) AS avg_role_order
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        RankedMovies rm ON ci.movie_id = rm.movie_id
    GROUP BY 
        a.person_id
),
CompanyStats AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies,
        COUNT(DISTINCT mc.company_id) AS total_companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    a.name,
    as.movie_count,
    as.avg_role_order,
    cs.companies,
    cs.total_companies,
    CASE 
        WHEN as.movie_count = 0 THEN 'No Roles'
        ELSE 'Active'
    END AS actor_status
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorStats as ON as.person_id = (SELECT person_id FROM cast_info ci WHERE ci.movie_id = rm.movie_id LIMIT 1)
LEFT JOIN 
    CompanyStats cs ON cs.movie_id = rm.movie_id
WHERE 
    rm.rank <= 5
ORDER BY 
    rm.production_year DESC, 
    rm.title;
