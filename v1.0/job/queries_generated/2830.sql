WITH ranked_movies AS (
    SELECT 
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    GROUP BY 
        t.title, t.production_year
), 
top_movies AS (
    SELECT 
        title, 
        production_year 
    FROM 
        ranked_movies 
    WHERE 
        rank <= 5
)
SELECT 
    tm.title,
    tm.production_year,
    COALESCE(ak.name, 'Unknown') AS actor_name,
    kv.keyword,
    CASE 
        WHEN mi.info IS NULL THEN 'No information available'
        ELSE mi.info
    END AS additional_info
FROM 
    top_movies tm
LEFT JOIN 
    complete_cast cc ON cc.movie_id = (SELECT id FROM aka_title WHERE title = tm.title AND production_year = tm.production_year LIMIT 1)
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.id
LEFT JOIN 
    aka_name ak ON ci.person_id = ak.person_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = (SELECT id FROM aka_title WHERE title = tm.title AND production_year = tm.production_year LIMIT 1)
LEFT JOIN 
    keyword kv ON mk.keyword_id = kv.id
LEFT JOIN 
    movie_info mi ON mi.movie_id = (SELECT id FROM aka_title WHERE title = tm.title AND production_year = tm.production_year LIMIT 1) 
WHERE 
    tm.production_year >= 2000
ORDER BY 
    tm.production_year DESC, 
    tm.title;
