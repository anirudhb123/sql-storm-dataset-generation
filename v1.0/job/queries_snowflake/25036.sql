
WITH ranked_titles AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        k.keyword AS genre,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY a.production_year DESC) AS title_rank,
        a.id AS movie_id
    FROM 
        aka_title a
    JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        a.production_year >= 2000
),
selected_cast AS (
    SELECT 
        c.movie_id,
        ak.name AS actor_name,
        ak.id AS actor_id,
        COUNT(DISTINCT c.role_id) AS roles_played
    FROM 
        cast_info c
    JOIN 
        aka_name ak ON ak.person_id = c.person_id
    WHERE 
        ak.name LIKE '%Smith%'
    GROUP BY 
        c.movie_id, ak.name, ak.id
),
movie_details AS (
    SELECT 
        rt.movie_title,
        rt.production_year,
        rt.genre,
        sc.actor_name,
        sc.roles_played
    FROM 
        ranked_titles rt
    JOIN 
        selected_cast sc ON rt.movie_id = sc.movie_id
    WHERE 
        rt.title_rank = 1
),
final_output AS (
    SELECT 
        md.movie_title,
        md.production_year,
        md.genre,
        md.actor_name,
        md.roles_played,
        CONCAT(md.actor_name, ' acted in ', md.movie_title, ' (', md.production_year, ') with genre ', md.genre) AS narrative
    FROM 
        movie_details md
)
SELECT 
    *
FROM 
    final_output
ORDER BY 
    production_year DESC, actor_name;
