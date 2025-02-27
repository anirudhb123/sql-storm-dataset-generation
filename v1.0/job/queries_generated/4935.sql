WITH MovieStatistics AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        AVG(CASE WHEN rc.role IS NOT NULL THEN 1 ELSE 0 END) AS average_role_assigned,
        STRING_AGG(DISTINCT COALESCE(cn.name, 'Unknown'), ', ') AS company_names
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    LEFT JOIN 
        role_type rc ON c.role_id = rc.id
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = t.id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    WHERE 
        t.production_year > 2000
    GROUP BY 
        t.id, t.title, t.production_year
), RankedMovies AS (
    SELECT 
        ms.movie_id,
        ms.title,
        ms.production_year,
        ms.actor_count,
        ms.average_role_assigned,
        ms.company_names,
        RANK() OVER (PARTITION BY ms.production_year ORDER BY ms.actor_count DESC) AS rank_by_actors
    FROM 
        MovieStatistics ms
)
SELECT 
    r.movie_id,
    r.title,
    r.production_year,
    r.actor_count,
    r.average_role_assigned,
    r.company_names
FROM 
    RankedMovies r
WHERE 
    r.rank_by_actors <= 5
    AND r.production_year IS NOT NULL
ORDER BY 
    r.production_year DESC, r.actor_count DESC;
