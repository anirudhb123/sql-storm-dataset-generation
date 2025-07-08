
WITH ranked_movies AS (
    SELECT 
        mt.title AS movie_title,
        mt.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        RANK() OVER (PARTITION BY mt.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS year_rank
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_companies mc ON mt.id = mc.movie_id
    LEFT JOIN 
        cast_info ci ON mt.id = ci.movie_id
    GROUP BY 
        mt.title, mt.production_year
),
winner_movies AS (
    SELECT 
        movie_title,
        production_year
    FROM 
        ranked_movies
    WHERE 
        year_rank = 1
),
keyword_movie_counts AS (
    SELECT 
        mk.movie_id,
        COUNT(DISTINCT k.keyword) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    wm.movie_title,
    wm.production_year,
    COALESCE(kmc.keyword_count, 0) AS total_keywords,
    ARRAY_AGG(DISTINCT an.name) AS actor_names,
    total_cast_in_winner.total_cast_count AS total_cast_in_winner
FROM 
    winner_movies wm
LEFT JOIN 
    movie_keyword mk ON wm.movie_title = (SELECT title FROM aka_title at WHERE at.id = mk.movie_id)
LEFT JOIN 
    keyword_movie_counts kmc ON mk.movie_id = kmc.movie_id
LEFT JOIN 
    (SELECT 
         c.movie_id, 
         COUNT(DISTINCT c.person_id) AS total_cast_count
     FROM 
         cast_info c
     JOIN 
         aka_title at ON at.id = c.movie_id
     GROUP BY 
         c.movie_id) total_cast_in_winner ON wm.movie_title = (SELECT title FROM aka_title at WHERE at.id = total_cast_in_winner.movie_id)
LEFT JOIN 
    cast_info ci ON wm.movie_title = (SELECT title FROM aka_title at WHERE at.id = ci.movie_id)
LEFT JOIN 
    aka_name an ON ci.person_id = an.person_id
GROUP BY 
    wm.movie_title, wm.production_year, kmc.keyword_count, total_cast_in_winner.total_cast_count
HAVING 
    COALESCE(kmc.keyword_count, 0) > 3
ORDER BY 
    wm.production_year DESC, total_keywords DESC;
