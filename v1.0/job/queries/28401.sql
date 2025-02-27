WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank
    FROM 
        aka_title AS t
    JOIN 
        movie_keyword AS mk ON t.id = mk.movie_id
    JOIN 
        keyword AS k ON mk.keyword_id = k.id
    WHERE 
        t.production_year IS NOT NULL 
        AND k.keyword IS NOT NULL
),
top_movies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        keyword
    FROM 
        ranked_movies
    WHERE 
        rank <= 3
),
movie_cast AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        r.role
    FROM 
        cast_info AS c
    JOIN 
        aka_name AS a ON c.person_id = a.person_id
    JOIN 
        role_type AS r ON c.role_id = r.id
    WHERE 
        a.name IS NOT NULL
)
SELECT 
    tm.movie_id,
    tm.title,
    tm.production_year,
    tm.keyword,
    STRING_AGG(DISTINCT mc.actor_name, ', ') AS cast_members,
    COUNT(DISTINCT mc.actor_name) AS total_cast_members
FROM 
    top_movies AS tm
LEFT JOIN 
    movie_cast AS mc ON tm.movie_id = mc.movie_id
GROUP BY 
    tm.movie_id, tm.title, tm.production_year, tm.keyword
ORDER BY 
    tm.production_year DESC, 
    tm.title;
