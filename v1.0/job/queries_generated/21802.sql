WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
cast_details AS (
    SELECT 
        ci.movie_id,
        ci.role_id,
        a.name AS actor_name,
        r.role AS role_name,
        COUNT(*) OVER (PARTITION BY ci.movie_id) AS total_cast,
        COALESCE(NULLIF(a.name, ''), 'Unknown Actor') AS safe_actor_name
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        role_type r ON ci.role_id = r.id
),
movies_with_actor_counts AS (
    SELECT 
        r.production_year,
        COUNT(DISTINCT cd.actor_name) AS actor_count
    FROM 
        ranked_titles r
    LEFT JOIN 
        cast_details cd ON r.title_id = cd.movie_id
    GROUP BY 
        r.production_year
),
high_actor_movies AS (
    SELECT 
        m.production_year,
        m.title,
        m.actor_count,
        RANK() OVER (ORDER BY m.actor_count DESC) AS actor_rank
    FROM 
        movies_with_actor_counts m
    WHERE 
        m.actor_count > 10
)
SELECT 
    r.title,
    r.production_year,
    COALESCE(h.actor_count, 0) AS number_of_actors,
    COALESCE(h.actor_rank, 'N/A') AS actor_rank
FROM 
    ranked_titles r
LEFT JOIN 
    high_actor_movies h ON r.title_id = h.title_id
WHERE 
    r.title IS NOT NULL
    AND (r.production_year BETWEEN 1990 AND 2000)
    AND (h.actor_count IS NULL OR h.actor_count > 5)
ORDER BY 
    r.production_year DESC,
    number_of_actors DESC;

-- Benchmarking for performance:
-- 1. Evaluate execution time for this CTE-heavy query.
-- 2. Test the impact of adding an index on both `cast_info` and `aka_title` on the `movie_id` column.
-- 3. Analyze how various levels of actor presence impact query performance and execution plans.

