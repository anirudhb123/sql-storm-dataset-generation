WITH ranked_titles AS (
    SELECT 
        at.title,
        at.production_year,
        ak.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.title) AS rn
    FROM 
        aka_title at
    JOIN 
        cast_info ci ON at.id = ci.movie_id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        at.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie') 
        AND at.production_year BETWEEN 2000 AND 2023
),
actor_counts AS (
    SELECT 
        actor_name,
        COUNT(*) AS movie_count
    FROM 
        ranked_titles
    GROUP BY 
        actor_name
),
top_actors AS (
    SELECT 
        actor_name
    FROM 
        actor_counts
    WHERE 
        movie_count > 5
)
SELECT 
    rt.rn,
    rt.title,
    rt.production_year,
    rt.actor_name,
    ac.movie_count
FROM 
    ranked_titles rt
JOIN 
    top_actors ta ON rt.actor_name = ta.actor_name
JOIN 
    actor_counts ac ON rt.actor_name = ac.actor_name
ORDER BY 
    rt.production_year, rt.rn;
