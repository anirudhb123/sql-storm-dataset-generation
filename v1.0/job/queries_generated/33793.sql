WITH RECURSIVE ActorHierarchy AS (
    SELECT 
        ci.person_id,
        t.title,
        t.production_year,
        ci.role_id,
        1 AS level
    FROM 
        cast_info ci
    JOIN 
        aka_title t ON ci.movie_id = t.id
    WHERE 
        ci.nr_order = 1  -- Starting point for recursion: main actor
    UNION ALL
    SELECT 
        ci.person_id,
        t.title,
        t.production_year,
        ci.role_id,
        ah.level + 1
    FROM 
        cast_info ci
    JOIN 
        aka_title t ON ci.movie_id = t.id
    JOIN 
        ActorHierarchy ah ON ci.movie_id = ah.movie_id
    WHERE 
        ci.nr_order > 1  -- Recursive case: subsequent actors in the cast
),
ActorStats AS (
    SELECT 
        a.person_id,
        a.title,
        COUNT(a.role_id) AS role_count,
        MIN(a.production_year) AS first_movie_year,
        MAX(a.production_year) AS last_movie_year,
        MAX(a.production_year) - MIN(a.production_year) AS career_span
    FROM 
        ActorHierarchy a
    GROUP BY 
        a.person_id, a.title
),
TopActors AS (
    SELECT 
        person_id,
        SUM(role_count) AS total_roles,
        AVG(career_span) AS avg_career_length
    FROM 
        ActorStats
    GROUP BY 
        person_id
    HAVING 
        SUM(role_count) > 3  -- Consider only prolific actors
)
SELECT 
    na.name, 
    ta.total_roles,
    ta.avg_career_length
FROM 
    TopActors ta
JOIN 
    aka_name na ON ta.person_id = na.person_id
WHERE 
    na.name IS NOT NULL
ORDER BY 
    ta.total_roles DESC
LIMIT 10;

### Query Explanation
1. **Recursive CTE (ActorHierarchy)**: This retrieves all levels of actors in movies. It starts with primary actors (where `nr_order = 1`) and recursively fetches subsequent actors in the same movies.
  
2. **Aggregated CTE (ActorStats)**: Here, we compute statistics per actor, gathering role counts and the span of their careers (by calculating the difference between their first and last movie years).

3. **Filtered CTE (TopActors)**: This final CTE filters actors who have had more than three roles, focusing on prolific actors. It sums up roles and calculates the average career length.

4. **Final Selection**: We join the results with the `aka_name` table to get the names of these prolific actors, ensuring that the names are not NULL, and then order the results based on the number of roles in descending order, limiting the result to the top 10.
