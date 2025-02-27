WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS year_rank
    FROM 
        aka_title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.id
    GROUP BY 
        t.id, t.title, t.production_year
),
PopularActors AS (
    SELECT 
        ak.name AS actor_name,
        COUNT(DISTINCT rc.movie_id) AS movie_count,
        ROW_NUMBER() OVER (ORDER BY COUNT(DISTINCT rc.movie_id) DESC) AS actor_rank
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    JOIN 
        RankedMovies rc ON ci.movie_id = rc.movie_id
    GROUP BY 
        ak.name
)
SELECT 
    pm.actor_name,
    pm.movie_count,
    rm.title,
    rm.production_year,
    rm.cast_count
FROM 
    PopularActors pm
JOIN 
    RankedMovies rm ON pm.movie_count >= 5 AND rm.year_rank <= 3
ORDER BY 
    pm.movie_count DESC, rm.production_year DESC;
