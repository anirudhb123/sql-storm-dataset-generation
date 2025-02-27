WITH ranked_movies AS (
    SELECT 
        a.title AS movie_title,
        t.production_year,
        COUNT(c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.person_id) DESC) AS rn
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE 'feature%')
    GROUP BY 
        a.title, t.production_year
),
average_cast AS (
    SELECT 
        production_year, 
        AVG(cast_count) AS average_cast_count
    FROM 
        ranked_movies
    GROUP BY 
        production_year
),
movies_above_average AS (
    SELECT 
        rm.movie_title,
        rm.production_year,
        rm.cast_count,
        ac.average_cast_count
    FROM 
        ranked_movies rm
    JOIN 
        average_cast ac ON rm.production_year = ac.production_year
    WHERE 
        rm.cast_count > ac.average_cast_count
)
SELECT 
    mab.movie_title,
    mab.production_year,
    mab.cast_count,
    (SELECT COUNT(DISTINCT mc.company_id) 
     FROM movie_companies mc 
     JOIN aka_title at ON mc.movie_id = at.id 
     WHERE at.title = mab.movie_title) AS company_count,
    (SELECT GROUP_CONCAT(name) 
     FROM company_name 
     WHERE imdb_id IN (SELECT DISTINCT mc.company_id FROM movie_companies mc WHERE mc.movie_id = (SELECT id FROM aka_title WHERE title = mab.movie_title))) AS company_names
FROM 
    movies_above_average mab
ORDER BY 
    mab.production_year DESC,
    mab.cast_count DESC;  
