WITH movie_character_count AS (
    SELECT 
        at.id AS movie_id, 
        LENGTH(at.title) - LENGTH(REPLACE(at.title, ' ', '')) + 1 AS character_count
    FROM 
        aka_title at
),
top_movies AS (
    SELECT 
        mc.movie_id,
        mc.character_count,
        ROW_NUMBER() OVER (ORDER BY mc.character_count DESC) AS rank
    FROM 
        movie_character_count mc
    WHERE 
        mc.character_count > 0
),
cast_and_titles AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        t.title AS movie_title
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        title t ON c.movie_id = t.id
)
SELECT 
    tm.movie_id,
    c.actor_name,
    c.movie_title,
    t.production_year,
    t.kind_id,
    tm.character_count AS title_character_count
FROM 
    top_movies tm
JOIN 
    cast_and_titles c ON tm.movie_id = c.movie_id
JOIN 
    aka_title t ON tm.movie_id = t.id
WHERE 
    tm.rank <= 10
ORDER BY 
    tm.character_count DESC, c.actor_name;
