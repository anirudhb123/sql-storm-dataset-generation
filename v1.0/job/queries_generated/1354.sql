WITH ranked_titles AS (
    SELECT 
        t.title, 
        t.production_year, 
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY RANDOM()) AS rn
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
    LIMIT 100
),
actors AS (
    SELECT 
        DISTINCT a.name,
        c.movie_id,
        c.nr_order
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    WHERE 
        a.name IS NOT NULL
),
movie_details AS (
    SELECT 
        m.title,
        m.production_year,
        COUNT(DISTINCT a.person_id) AS actor_count,
        STRING_AGG(a.name, ', ') AS actors_list
    FROM 
        ranked_titles m
    LEFT JOIN 
        cast_info c ON m.id = c.movie_id
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        m.title, m.production_year
)
SELECT 
    md.title,
    md.production_year,
    COALESCE(md.actor_count, 0) AS total_actors,
    CASE 
        WHEN md.actor_count IS NULL OR md.actor_count = 0 THEN 'No Actors'
        ELSE md.actors_list
    END AS actors
FROM 
    movie_details md
WHERE 
    md.production_year >= 2000
ORDER BY 
    md.production_year DESC, md.total_actors DESC
LIMIT 50;
