WITH movie_cast AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        c.person_id,
        p.name AS actor_name,
        RANK() OVER (PARTITION BY m.id ORDER BY ci.nr_order) AS role_rank
    FROM 
        aka_title m
    JOIN 
        cast_info ci ON m.id = ci.movie_id
    JOIN 
        aka_name p ON ci.person_id = p.person_id
    WHERE 
        p.name IS NOT NULL AND 
        m.production_year >= 2000
),
actor_roles AS (
    SELECT 
        mc.movie_id,
        mc.title,
        mc.actor_name,
        COALESCE(rt.role, 'Unknown') AS role,
        mc.role_rank
    FROM 
        movie_cast mc
    LEFT JOIN 
        role_type rt ON mc.person_id = rt.id
),
filtered_movies AS (
    SELECT 
        m.title,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM 
        movie_cast m
    LEFT JOIN 
        cast_info c ON m.movie_id = c.movie_id
    GROUP BY 
        m.title
    HAVING 
        COUNT(DISTINCT c.person_id) > 3
),
final_results AS (
    SELECT 
        f.title,
        a.actor_name,
        a.role,
        f.actor_count
    FROM 
        filtered_movies f
    JOIN 
        actor_roles a ON f.title = a.title
    WHERE 
        a.role_rank = 1  -- Top billed actor
)
SELECT 
    f.title,
    f.actor_name,
    f.role,
    f.actor_count,
    CASE 
        WHEN f.actor_count IS NULL THEN 'No actors found'
        WHEN f.actor_count > 10 THEN 'Star-studded cast'
        ELSE 'Moderate cast'
    END AS cast_description
FROM 
    final_results f
ORDER BY 
    f.actor_count DESC, 
    f.title ASC;

-- Additional considerations for benchmarking:
-- Calculate the average role rank of main actors in filtered movies
WITH role_ranks_avg AS (
    SELECT 
        movie_id,
        AVG(role_rank) AS average_role_rank
    FROM 
        movie_cast
    GROUP BY 
        movie_id
)
SELECT 
    f.title,
    COALESCE(r.average_role_rank, -1) AS avg_role_rank
FROM 
    filtered_movies f
LEFT JOIN 
    role_ranks_avg r ON f.movie_id = r.movie_id
WHERE 
    f.actor_count > 5;
