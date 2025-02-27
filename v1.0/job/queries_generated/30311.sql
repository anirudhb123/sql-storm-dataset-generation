WITH RECURSIVE actor_hierarchy AS (
    SELECT 
        c.person_id,
        p.name AS actor_name,
        1 AS generation
    FROM 
        cast_info c
    JOIN 
        aka_name p ON c.person_id = p.person_id
    WHERE 
        p.name IS NOT NULL

    UNION ALL

    SELECT 
        c.person_id,
        p.name AS actor_name,
        ah.generation + 1
    FROM 
        cast_info c
    JOIN 
        actor_hierarchy ah ON c.movie_id IN (
            SELECT movie_id 
            FROM cast_info 
            WHERE person_id = ah.person_id
        )
    JOIN 
        aka_name p ON c.person_id = p.person_id
    WHERE 
        p.name IS NOT NULL AND ah.generation < 3
),

filmography AS (
    SELECT 
        t.title,
        t.production_year,
        a.actor_name,
        ROW_NUMBER() OVER (PARTITION BY a.actor_name ORDER BY t.production_year DESC) AS movie_rank,
        COUNT(*) OVER (PARTITION BY a.actor_name) AS total_movies
    FROM 
        title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        t.production_year >= 2000
)

SELECT 
    f.actor_name,
    f.total_movies,
    AVG(f.production_year) AS avg_production_year,
    STRING_AGG(f.title, ', ') AS movies,
    CASE 
        WHEN f.total_movies > 10 THEN 'Veteran'
        WHEN f.total_movies BETWEEN 5 AND 10 THEN 'Intermediate'
        ELSE 'Rookie'
    END AS experience_level
FROM 
    filmography f
GROUP BY 
    f.actor_name, f.total_movies
HAVING 
    COUNT(*) FILTER (WHERE f.movie_rank = 1) > 2
ORDER BY 
    avg_production_year DESC;

-- This query builds a recursing **actor hierarchy** to explore relationships between actors 
-- based on their shared movie participation, collects a **filmography** for actors in titles 
-- produced since the year 2000, and finally summarizes their experience level based on movie appearances.
