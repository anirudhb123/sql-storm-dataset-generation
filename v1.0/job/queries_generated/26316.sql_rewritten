WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS row_num
    FROM 
        aka_title t
    WHERE 
        t.production_year >= 2000
), filtered_cast AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS cast_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        c.nr_order < 5 
    GROUP BY 
        c.movie_id
), movie_details AS (
    SELECT 
        t.title,
        t.production_year,
        f.cast_count,
        f.actor_names
    FROM 
        ranked_titles t
    LEFT JOIN 
        filtered_cast f ON t.title_id = f.movie_id
)
SELECT 
    md.production_year,
    COUNT(md.title) AS movie_count,
    AVG(md.cast_count) AS average_cast_count,
    STRING_AGG(md.actor_names, '; ') AS actors_list
FROM 
    movie_details md
GROUP BY 
    md.production_year
ORDER BY 
    md.production_year DESC
LIMIT 10;