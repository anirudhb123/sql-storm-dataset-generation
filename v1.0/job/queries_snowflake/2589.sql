
WITH movie_details AS (
    SELECT 
        a.title,
        at.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        LISTAGG(DISTINCT ak.name, ', ') WITHIN GROUP (ORDER BY ak.name) AS actor_names
    FROM 
        aka_title at
    JOIN 
        title a ON at.movie_id = a.id
    LEFT JOIN 
        cast_info c ON c.movie_id = a.id
    LEFT JOIN 
        aka_name ak ON ak.person_id = c.person_id
    WHERE 
        at.production_year >= 2000 
        AND a.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
    GROUP BY 
        a.title, at.production_year
),
high_actor_movies AS (
    SELECT 
        md.title,
        md.production_year,
        md.actor_count,
        md.actor_names,
        ROW_NUMBER() OVER (PARTITION BY md.production_year ORDER BY md.actor_count DESC) AS rn
    FROM 
        movie_details md
    WHERE 
        md.actor_count > 5
)
SELECT 
    ham.title,
    ham.production_year,
    ham.actor_count,
    ham.actor_names,
    CASE 
        WHEN ham.actor_count IS NULL THEN 'Unknown' 
        ELSE CAST(ham.actor_count AS VARCHAR) 
    END AS actor_count_text
FROM 
    high_actor_movies ham
WHERE 
    ham.rn <= 10
ORDER BY 
    ham.production_year DESC, ham.actor_count DESC;
