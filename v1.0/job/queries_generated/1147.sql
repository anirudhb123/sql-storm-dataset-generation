WITH ranked_movies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.id) DESC) AS rank_by_cast
    FROM 
        title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.person_id
    GROUP BY 
        t.id
),
top_movies AS (
    SELECT 
        title_id,
        title,
        production_year
    FROM 
        ranked_movies 
    WHERE 
        rank_by_cast <= 5
),
actors_with_keywords AS (
    SELECT 
        a.name AS actor_name,
        k.keyword
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        movie_keyword mk ON ci.movie_id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
)
SELECT 
    tm.title,
    tm.production_year,
    STRING_AGG(DISTINCT ak.actor_name, ', ') AS actor_names,
    STRING_AGG(DISTINCT ak.keyword, ', ') AS keywords
FROM 
    top_movies tm
LEFT JOIN 
    actors_with_keywords ak ON tm.title_id = ak.movie_id
GROUP BY 
    tm.title, tm.production_year
ORDER BY 
    tm.production_year DESC, COUNT(ak.actor_name) DESC
LIMIT 10;
