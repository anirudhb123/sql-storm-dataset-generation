WITH ranked_titles AS (
    SELECT 
        at.title, 
        at.production_year, 
        ak.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY LENGTH(at.title) DESC) AS title_rank
    FROM 
        aka_title at
    JOIN 
        cast_info ci ON at.movie_id = ci.movie_id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        ak.name IS NOT NULL
),
filtered_ranked_titles AS (
    SELECT 
        rt.* 
    FROM 
        ranked_titles rt
    WHERE 
        rt.title_rank <= 5
)
SELECT 
    frt.production_year, 
    STRING_AGG(frt.title, ', ') AS top_titles,
    STRING_AGG(frt.actor_name, ', ') AS top_actors
FROM 
    filtered_ranked_titles frt
GROUP BY 
    frt.production_year
ORDER BY 
    frt.production_year DESC;