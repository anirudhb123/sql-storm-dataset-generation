WITH RankedMovies AS (
    SELECT 
        at.title,
        at.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS year_rank
    FROM 
        aka_title at
    LEFT JOIN 
        cast_info ci ON at.id = ci.movie_id
    WHERE 
        at.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('movie', 'feature'))
    GROUP BY 
        at.id, at.title, at.production_year
), ActorInfo AS (
    SELECT 
        a.name,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        AVG(CASE WHEN ci.nr_order IS NULL THEN 0 ELSE ci.nr_order END) AS avg_order
    FROM 
        aka_name a
    LEFT JOIN 
        cast_info ci ON a.person_id = ci.person_id
    GROUP BY 
        a.id, a.name
)
SELECT 
    rm.title,
    rm.production_year,
    rm.cast_count,
    ai.name AS actor_name,
    ai.movie_count,
    ai.avg_order
FROM 
    RankedMovies rm
JOIN 
    ActorInfo ai ON rm.cast_count > 5 AND EXISTS (
        SELECT 1 
        FROM cast_info c
        WHERE c.movie_id = rm.title 
        AND c.person_id = ai.person_id
    )
WHERE 
    rm.year_rank <= 3
ORDER BY 
    rm.production_year DESC, 
    rm.cast_count DESC;
