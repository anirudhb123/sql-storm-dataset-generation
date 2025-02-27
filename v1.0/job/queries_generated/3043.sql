WITH RankedMovies AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        COUNT(ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank_per_year
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.title, t.production_year
),
ActorInfo AS (
    SELECT 
        an.name AS actor_name,
        COUNT(DISTINCT ci.movie_id) AS movies_count,
        AVG(EXTRACT(YEAR FROM CURRENT_DATE) - t.production_year) AS average_movie_age
    FROM 
        aka_name an
    INNER JOIN 
        cast_info ci ON an.person_id = ci.person_id
    INNER JOIN 
        aka_title t ON ci.movie_id = t.id
    GROUP BY 
        an.name
    HAVING 
        COUNT(DISTINCT ci.movie_id) > 5
)
SELECT 
    rm.movie_title,
    rm.production_year,
    rm.cast_count,
    ai.actor_name,
    ai.movies_count,
    COALESCE(ai.average_movie_age, 0) AS average_movie_age,
    (CASE 
        WHEN rm.cast_count > 10 THEN 'Large Cast' 
        WHEN rm.cast_count BETWEEN 5 AND 10 THEN 'Medium Cast' 
        ELSE 'Small Cast' 
    END) AS cast_size_category
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorInfo ai ON rm.cast_count > ai.movies_count
WHERE 
    rm.rank_per_year <= 5
ORDER BY 
    rm.production_year DESC, 
    rm.cast_count DESC;
