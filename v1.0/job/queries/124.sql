
WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        RANK() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    GROUP BY 
        a.title, a.production_year
),
TopActors AS (
    SELECT 
        ak.name AS actor_name,
        COUNT(DISTINCT ci.movie_id) AS movies_count
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    JOIN 
        movie_companies mc ON ci.movie_id = mc.movie_id
    WHERE 
        mc.company_type_id IN (
            SELECT id FROM company_type WHERE kind = 'Production'
        )
    GROUP BY 
        ak.name
    HAVING 
        COUNT(DISTINCT mc.movie_id) > 5
),
ProductionYears AS (
    SELECT 
        DISTINCT rm.production_year 
    FROM 
        RankedMovies rm 
    WHERE 
        rm.actor_count > 10
)
SELECT 
    rm.title,
    rm.production_year,
    COALESCE(ta.actor_name, 'Unknown Actor') AS prominent_actor,
    ta.movies_count AS prominent_actor_movies
FROM 
    RankedMovies rm
LEFT JOIN 
    TopActors ta ON rm.actor_count > 10 AND rm.rank = 1
JOIN 
    ProductionYears py ON rm.production_year = py.production_year
ORDER BY 
    rm.production_year DESC, rm.actor_count DESC;
