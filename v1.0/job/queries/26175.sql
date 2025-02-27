
WITH ranked_movies AS (
    SELECT 
        at.title AS movie_title,
        at.production_year,
        ak.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY at.id ORDER BY ak.name) AS actor_rank
    FROM 
        aka_title at
    JOIN 
        cast_info ci ON at.id = ci.movie_id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        at.production_year BETWEEN 2000 AND 2023
        AND ak.name IS NOT NULL
),
movie_info_with_keywords AS (
    SELECT 
        rm.movie_title,
        rm.production_year,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        ranked_movies rm
    LEFT JOIN 
        movie_keyword mk ON rm.movie_title = (SELECT title FROM aka_title WHERE id = mk.movie_id)
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        rm.movie_title, rm.production_year
),
top_movies AS (
    SELECT 
        movie_title,
        production_year,
        keywords,
        COUNT(*) AS actor_count
    FROM 
        movie_info_with_keywords
    GROUP BY 
        movie_title, production_year, keywords
    ORDER BY 
        actor_count DESC
    LIMIT 10
)
SELECT 
    tm.movie_title,
    tm.production_year,
    tm.keywords
FROM 
    top_movies tm
JOIN 
    movie_info mi ON tm.movie_title = mi.info AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Box Office')
WHERE 
    mi.note IS NOT NULL
ORDER BY 
    tm.production_year DESC;
