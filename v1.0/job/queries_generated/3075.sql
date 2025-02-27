WITH RankedMovies AS (
    SELECT 
        mt.title,
        mt.production_year,
        COUNT(DISTINCT mc.company_id) AS company_count,
        DENSE_RANK() OVER (ORDER BY mt.production_year DESC) AS year_rank
    FROM 
        aka_title mt
    JOIN 
        movie_companies mc ON mt.id = mc.movie_id
    GROUP BY 
        mt.title, mt.production_year
),
ActorRoles AS (
    SELECT 
        ai.person_id,
        ai.name,
        ci.movie_id,
        ri.role,
        ROW_NUMBER() OVER (PARTITION BY ai.person_id ORDER BY ci.nr_order) AS role_rank
    FROM 
        aka_name ai
    JOIN 
        cast_info ci ON ai.person_id = ci.person_id
    JOIN 
        role_type ri ON ci.role_id = ri.id
),
FeaturedMovies AS (
    SELECT 
        mv.title,
        mv.production_year,
        rv.year_rank,
        COUNT(DISTINCT ar.person_id) AS actor_count
    FROM 
        RankedMovies rv
    LEFT JOIN 
        ActorRoles ar ON rv.title = ar.title AND rv.production_year = ar.production_year
    JOIN 
        aka_title mv ON rv.title = mv.title AND rv.production_year = mv.production_year
    GROUP BY 
        mv.title, mv.production_year, rv.year_rank
)
SELECT 
    fm.title,
    fm.production_year,
    fm.year_rank,
    COALESCE(fm.actor_count, 0) as actor_count,
    CASE 
        WHEN fm.actor_count > 10 THEN 'Blockbuster'
        WHEN fm.actor_count BETWEEN 5 AND 10 THEN 'Moderate Hit'
        ELSE 'Flop'
    END AS performance_category
FROM 
    FeaturedMovies fm
WHERE 
    fm.actor_count IS NULL OR fm.actor_count > 0
ORDER BY 
    fm.production_year DESC, fm.actor_count DESC;
