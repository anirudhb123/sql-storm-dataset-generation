WITH RECURSIVE ActorMovies AS (
    SELECT 
        c.person_id,
        t.title,
        t.production_year,
        COALESCE(SUM(CASE WHEN r.role = 'lead' THEN 1 ELSE 0 END), 0) AS lead_role_count
    FROM 
        cast_info AS c
    JOIN 
        title AS t ON c.movie_id = t.id
    LEFT JOIN 
        role_type AS r ON c.role_id = r.id
    GROUP BY 
        c.person_id, t.title, t.production_year
),

ActorInfo AS (
    SELECT 
        a.person_id,
        ak.name AS actor_name,
        COUNT(*) AS total_movies,
        AVG(am.lead_role_count) AS avg_lead_roles
    FROM 
        aka_name AS ak
    JOIN 
        ActorMovies AS am ON ak.person_id = am.person_id
    GROUP BY 
        a.person_id, ak.name
),

PopularActors AS (
    SELECT 
        a.actor_name,
        a.total_movies,
        a.avg_lead_roles,
        RANK() OVER (ORDER BY a.total_movies DESC) AS rank_total_movies,
        RANK() OVER (ORDER BY a.avg_lead_roles DESC) AS rank_avg_lead_roles
    FROM 
        ActorInfo AS a
    WHERE 
        a.total_movies > 10
) 

SELECT 
    pa.actor_name,
    pa.total_movies,
    pa.avg_lead_roles,
    CASE 
        WHEN pa.rank_total_movies = 1 THEN 'Top Actor'
        ELSE 'Ranked Actor'
    END AS actor_status,
    COALESCE(cn.country_code, 'Unknown') AS country_code
FROM 
    PopularActors AS pa
LEFT JOIN 
    company_name AS cn ON pa.actor_name ILIKE '%' || cn.name || '%'
ORDER BY 
    pa.rank_total_movies, pa.avg_lead_roles DESC;
This SQL query accomplishes the following tasks:

1. **Recursive CTE (`ActorMovies`)**: It aggregates movies and lead roles for each actor.
2. **Actor Info Aggregation**: In `ActorInfo`, it calculates the total number of movies and average lead roles per actor.
3. **Popularity Ranking**: The `PopularActors` CTE ranks actors based on the total number of movies and average lead roles, filtering for actors who have appeared in more than ten movies.
4. **Final Selection**: It selects actor details and additionally correlates their names with companies to determine their country of operation, using outer joins to ensure all actors are included, even those with no associated company. 
5. **Dynamic Status Assignment**: Adds a column to define actor status based on ranking.
6. **NULL Handling**: Uses `COALESCE` to handle and replace NULL values for country codes. 

This query is complex and leverages multiple SQL features such as CTEs, window functions, joins, and conditional logic, making it suitable for performance benchmarking in a real-world scenario.
