WITH ranked_titles AS (
    SELECT 
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY t.production_year DESC) AS rn
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    WHERE 
        a.name IS NOT NULL
        AND t.production_year IS NOT NULL
),
recent_movies AS (
    SELECT 
        actor_name,
        movie_title,
        production_year
    FROM 
        ranked_titles
    WHERE 
        rn <= 3
),
keyword_info AS (
    SELECT 
        m.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword m
    JOIN 
        keyword k ON m.keyword_id = k.id
    GROUP BY 
        m.movie_id
)
SELECT 
    rm.actor_name,
    rm.movie_title,
    rm.production_year,
    COALESCE(ki.keywords, 'No keywords') AS keywords
FROM 
    recent_movies rm
LEFT JOIN 
    keyword_info ki ON rm.movie_title = ki.movie_id
ORDER BY 
    rm.actor_name, 
    rm.production_year DESC;
