WITH RankedMovies AS (
    SELECT 
        at.id AS title_id,
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.production_year DESC) AS year_rank,
        COUNT(ci.role_id) OVER (PARTITION BY at.id) AS cast_count
    FROM 
        aka_title at
    LEFT JOIN 
        cast_info ci ON at.movie_id = ci.movie_id
    WHERE 
        at.production_year IS NOT NULL
),
ActorsCount AS (
    SELECT 
        ak.person_id,
        ak.name,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        aka_name ak
    LEFT JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    GROUP BY 
        ak.person_id, ak.name
    HAVING 
        COUNT(DISTINCT ci.movie_id) > 5
),
HighestRatedRoles AS (
    SELECT 
        ci.person_id,
        rt.role,
        COUNT(*) AS role_count
    FROM 
        cast_info ci
    JOIN 
        role_type rt ON ci.role_id = rt.id
    WHERE 
        ci.note IS NOT NULL
    GROUP BY 
        ci.person_id, rt.role
    HAVING 
        COUNT(*) >= 3
),
MovieDetails AS (
    SELECT 
        rm.title_id,
        rm.title,
        rm.production_year,
        rm.cast_count,
        ac.movie_count AS actor_movie_count
    FROM 
        RankedMovies rm
    LEFT JOIN 
        ActorsCount ac ON rm.title_id IN (SELECT movie_id FROM cast_info WHERE person_id = ac.person_id)
)
SELECT 
    md.title,
    md.production_year,
    md.cast_count,
    COALESCE(hrr.role_count, 0) AS popular_roles,
    md.actor_movie_count
FROM 
    MovieDetails md
LEFT JOIN 
    HighestRatedRoles hrr ON md.title_id IN (SELECT movie_id FROM cast_info WHERE person_id = hrr.person_id)
WHERE 
    md.cast_count > 3
OR (md.production_year < 2000 AND md.actor_movie_count IS NULL)
ORDER BY 
    md.production_year DESC, md.cast_count DESC;
This SQL query performs a series of complex operations on the `Join Order Benchmark` schema. It includes CTEs to compute rankings and aggregates such as `WITH` clauses, outer joins, row numbering, and conditional logic through multiple predicates. The query aims to extract detailed movie and actor information while accounting for nuanced conditions around movie production years and actor roles.
