
WITH ranked_movies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.title, t.production_year
), top_movies AS (
    SELECT 
        title, 
        production_year 
    FROM 
        ranked_movies 
    WHERE 
        rank <= 5
), movie_details AS (
    SELECT 
        tm.title,
        tm.production_year,
        mi.info AS movie_info,
        COALESCE(ARRAY_TO_STRING(ARRAY_AGG(DISTINCT kw.keyword), ', '), 'No Keywords') AS keywords
    FROM 
        top_movies tm
    LEFT JOIN 
        movie_info mi ON mi.movie_id = (SELECT id FROM aka_title WHERE title = tm.title AND production_year = tm.production_year LIMIT 1)
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = (SELECT id FROM aka_title WHERE title = tm.title AND production_year = tm.production_year LIMIT 1)
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    GROUP BY 
        tm.title, tm.production_year, mi.info
)
SELECT 
    md.title,
    md.production_year,
    md.movie_info,
    md.keywords,
    ak.name AS actor_name
FROM 
    movie_details md
LEFT JOIN 
    complete_cast cc ON cc.movie_id = (SELECT id FROM aka_title WHERE title = md.title AND production_year = md.production_year LIMIT 1)
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.id
LEFT JOIN 
    aka_name ak ON ci.person_id = ak.person_id
WHERE 
    ak.name IS NOT NULL
ORDER BY 
    md.production_year DESC, md.title;
