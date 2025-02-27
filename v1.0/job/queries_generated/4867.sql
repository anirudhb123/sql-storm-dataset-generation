WITH RankedMovies AS (
    SELECT 
        a.id AS actor_id,
        a.name,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER(PARTITION BY a.id ORDER BY t.production_year DESC) AS movie_rank
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        aka_title t ON ci.movie_id = t.movie_id
    WHERE 
        t.production_year IS NOT NULL
),
TopActors AS (
    SELECT 
        actor_id,
        name,
        COUNT(*) AS movie_count
    FROM 
        RankedMovies
    WHERE 
        movie_rank <= 5
    GROUP BY 
        actor_id, name
    HAVING 
        COUNT(*) >= 3
)
SELECT 
    ta.name,
    ta.movie_count,
    ARRAY_AGG(DISTINCT rm.title) AS top_movies,
    COALESCE(NULLIF((SELECT COUNT(DISTINCT movie_id) FROM movie_info mi WHERE mi.info_type_id = 1 AND mi.info LIKE '%award%'), 0), 'No Awards') AS award_count
FROM 
    TopActors ta
LEFT JOIN 
    RankedMovies rm ON ta.actor_id = rm.actor_id
GROUP BY 
    ta.actor_id, ta.name, ta.movie_count
HAVING 
    ta.movie_count > 5
ORDER BY 
    ta.movie_count DESC
LIMIT 10;
