
WITH ranked_movies AS (
    SELECT 
        t.title,
        t.production_year,
        a.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS actor_rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.title, t.production_year, a.name
),
top_actors AS (
    SELECT 
        actor_name,
        production_year
    FROM 
        ranked_movies
    WHERE 
        actor_rank <= 3
),
movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        k.keyword,
        mi.info
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_info mi ON t.id = mi.movie_id
    WHERE 
        mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Summary') OR mi.info IS NULL
)
SELECT 
    md.title,
    md.production_year,
    COALESCE(ta.actor_name, 'No actors') AS top_actor,
    LISTAGG(DISTINCT md.keyword, ', ') WITHIN GROUP (ORDER BY md.keyword) AS keywords,
    COUNT(DISTINCT md.movie_id) AS related_movies_count,
    CASE 
        WHEN md.production_year < 2000 THEN 'Classic'
        WHEN md.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
        ELSE 'Recent'
    END AS era
FROM 
    movie_details md
LEFT JOIN 
    top_actors ta ON md.production_year = ta.production_year
LEFT JOIN 
    ranked_movies r ON md.title = r.title
GROUP BY 
    md.title, md.production_year, ta.actor_name
ORDER BY 
    md.production_year DESC, related_movies_count DESC
LIMIT 10;
