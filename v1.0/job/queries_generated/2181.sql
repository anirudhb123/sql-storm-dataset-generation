WITH ranked_movies AS (
    SELECT 
        t.title, 
        t.production_year, 
        COUNT(DISTINCT ci.person_id) AS cast_count, 
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    WHERE 
        t.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie') 
        AND t.production_year IS NOT NULL
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
),
movie_details AS (
    SELECT 
        tm.title, 
        tm.production_year, 
        GROUP_CONCAT(DISTINCT ak.name) AS actor_names,
        (SELECT AVG(pi.info::float) 
         FROM person_info pi 
         WHERE pi.person_id IN (SELECT ci.person_id FROM cast_info ci WHERE ci.movie_id IN (SELECT id FROM aka_title WHERE title = tm.title))
         AND pi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')) AS avg_rating
    FROM 
        top_movies tm
    LEFT JOIN 
        cast_info ci ON ci.movie_id IN (SELECT id FROM aka_title WHERE title = tm.title)
    LEFT JOIN 
        aka_name ak ON ak.person_id = ci.person_id
    GROUP BY 
        tm.title, tm.production_year
)
SELECT 
    md.title,
    md.production_year,
    COALESCE(md.actor_names, 'No actors available') AS actor_names,
    COALESCE(md.avg_rating, 'No rating available') AS avg_rating
FROM 
    movie_details md
WHERE 
    md.production_year BETWEEN 2000 AND 2023
ORDER BY 
    md.production_year DESC, md.title;
