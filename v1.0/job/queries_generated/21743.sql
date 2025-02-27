WITH RECURSIVE movie_graph AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level,
        ARRAY[m.id] AS path
    FROM 
        aka_title AS m
    WHERE 
        m.production_year IS NOT NULL
    UNION ALL
    SELECT 
        linked_movie.linked_movie_id,
        sub.title,
        sub.production_year,
        mg.level + 1,
        path || linked_movie.linked_movie_id
    FROM 
        movie_link AS linked_movie
    JOIN 
        aka_title AS sub ON linked_movie.movie_id = sub.id
    JOIN 
        movie_graph AS mg ON linked_movie.movie_id = mg.movie_id
    WHERE 
        linked_movie.linked_movie_id <> ALL(mg.path) AND 
        sub.production_year IS NOT NULL
),
movie_cast AS (
    SELECT 
        c.movie_id,
        STRING_AGG(DISTINCT a.name, ', ') AS actors,
        COUNT(DISTINCT c.role_id) AS total_roles,
        COUNT(DISTINCT c.person_id) AS total_cast,
        AVG(CASE 
                WHEN r.role = 'Lead' THEN 1 
                ELSE 0 
            END) AS lead_actor_ratio
    FROM 
        cast_info AS c
    JOIN 
        aka_name AS a ON c.person_id = a.person_id
    JOIN 
        role_type AS r ON c.role_id = r.id
    GROUP BY 
        c.movie_id
),
combined_results AS (
    SELECT 
        mg.movie_id,
        mg.title,
        mg.production_year,
        mc.actors,
        mc.total_roles,
        mc.total_cast,
        mc.lead_actor_ratio,
        ROW_NUMBER() OVER (PARTITION BY mg.production_year ORDER BY mc.total_cast DESC) AS rank_per_year,
        CASE 
            WHEN mc.lead_actor_ratio > 0.5 THEN 'High Lead Ratio'
            WHEN mc.total_roles > 10 THEN 'High Role Count'
            ELSE 'Regular Cast'
        END AS classification
    FROM 
        movie_graph AS mg
    LEFT JOIN 
        movie_cast AS mc ON mg.movie_id = mc.movie_id
)
SELECT 
    c.production_year,
    COUNT(c.movie_id) AS movie_count,
    SUM(CASE WHEN c.classification = 'High Lead Ratio' THEN 1 ELSE 0 END) AS high_lead_count,
    MAX(c.total_cast) AS max_cast,
    MIN(c.total_roles) AS min_roles,
    STRING_AGG(DISTINCT c.title, ', ') AS titles
FROM 
    combined_results AS c
WHERE 
    c.production_year IS NOT NULL AND 
    c.actors IS NOT NULL
GROUP BY 
    c.production_year
HAVING 
    COUNT(c.movie_id) > 5
ORDER BY 
    c.production_year DESC;
This SQL query encompasses various advanced constructs to perform a performance benchmarking analysis on the given film-related schema. It utilizes CTEs for recursive movie relationships, aggregates actor information while handling roles, and classifies movies based on their cast composition. Additionally, it handles NULL logic and peculiar corner cases effectively, illustrating the complexity that can arise in performance queries.
