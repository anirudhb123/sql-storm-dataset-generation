
WITH ranked_movies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COUNT(DISTINCT m.id) AS company_count,
        AVG(CAST(SUBSTRING(mi.info, 'Rating: (\\d+\\.\\d+)') AS FLOAT)) AS average_rating,
        ROW_NUMBER() OVER (ORDER BY COUNT(DISTINCT m.id) DESC, AVG(CAST(SUBSTRING(mi.info, 'Rating: (\\d+\\.\\d+)') AS FLOAT)) DESC) AS rank
    FROM 
        aka_title mt
    JOIN 
        movie_companies mc ON mt.id = mc.movie_id
    JOIN 
        company_name m ON mc.company_id = m.id
    LEFT JOIN 
        movie_info mi ON mt.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Rating')
    GROUP BY 
        mt.id, mt.title, mt.production_year
),
top_movies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.company_count,
        rm.average_rating
    FROM 
        ranked_movies rm
    WHERE 
        rm.rank <= 10  
)
SELECT 
    tm.title,
    tm.production_year,
    tm.company_count,
    tm.average_rating,
    LISTAGG(DISTINCT a.name, ', ') AS co_actors
FROM 
    top_movies tm
JOIN 
    complete_cast cc ON tm.movie_id = cc.movie_id
JOIN 
    aka_name a ON cc.subject_id = a.person_id
GROUP BY 
    tm.title, tm.production_year, tm.company_count, tm.average_rating
ORDER BY 
    tm.average_rating DESC;
