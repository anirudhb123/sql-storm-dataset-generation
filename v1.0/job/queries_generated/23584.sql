WITH Recursive ActorMovies AS (
    SELECT 
        c.person_id, 
        a.name AS actor_name, 
        t.title AS movie_title, 
        t.production_year, 
        ROW_NUMBER() OVER (PARTITION BY c.person_id ORDER BY t.production_year DESC) AS movie_rank 
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    WHERE 
        t.production_year IS NOT NULL
),
ActorStats AS (
    SELECT 
        person_id,
        actor_name,
        COUNT(DISTINCT movie_title) AS total_movies,
        MAX(production_year) AS last_year_active,
        MIN(production_year) AS first_year_active
    FROM 
        ActorMovies
    GROUP BY 
        person_id, actor_name
),
TopActors AS (
    SELECT 
        actor_name, 
        total_movies,
        (last_year_active - first_year_active) AS career_span,
        NTILE(3) OVER (ORDER BY total_movies DESC) AS performance_tier
    FROM 
        ActorStats
    WHERE 
        total_movies > 5
)
SELECT 
    ta.actor_name,
    ta.total_movies,
    ta.last_year_active,
    ta.first_year_active,
    ta.career_span,
    CASE 
        WHEN ta.performance_tier = 1 THEN 'Platinum'
        WHEN ta.performance_tier = 2 THEN 'Gold'
        ELSE 'Silver'
    END AS performance_label,
    STRING_AGG(DISTINCT am.movie_title || ' (' || am.production_year || ')', ', ') AS movies
FROM 
    TopActors ta
LEFT JOIN 
    ActorMovies am ON ta.actor_name = am.actor_name
GROUP BY 
    ta.actor_name, ta.total_movies, ta.last_year_active, ta.first_year_active, ta.career_span, ta.performance_tier
ORDER BY 
    ta.total_movies DESC;

This complex SQL query utilizes:
- Common Table Expressions (CTEs) for modular query design and better readability.
- Recursive CTEs for potential expansion or further nested queries.
- Window functions like `ROW_NUMBER` and `NTILE` for ranking purposes.
- Aggregation with `STRING_AGG` to create a comma-separated list of movies per actor.
- Various filtering and grouping techniques that add complexity and cover edge cases like NULL production years.
- Case statements to transform numeric rank into a more semantic label.
