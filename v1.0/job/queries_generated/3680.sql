WITH ranked_movies AS (
    SELECT 
        title.id AS movie_id,
        title.title,
        title.production_year,
        COUNT(DISTINCT cast_info.person_id) AS cast_count,
        AVG(person_info.info::float) AS avg_rating,
        DENSE_RANK() OVER (PARTITION BY title.production_year ORDER BY COUNT(DISTINCT cast_info.person_id) DESC) AS rank
    FROM 
        title 
    LEFT JOIN 
        cast_info ON title.id = cast_info.movie_id 
    LEFT JOIN 
        person_info ON cast_info.person_id = person_info.person_id 
    WHERE 
        person_info.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
    GROUP BY 
        title.id, title.title, title.production_year
),
top_movies AS (
    SELECT 
        movie_id, 
        title, 
        production_year, 
        cast_count, 
        avg_rating
    FROM 
        ranked_movies
    WHERE 
        rank <= 5
),
company_movies AS (
    SELECT 
        m.movie_id,
        GROUP_CONCAT(c.name) AS company_names
    FROM 
        movie_companies AS m
    JOIN 
        company_name AS c ON m.company_id = c.id
    GROUP BY 
        m.movie_id
)
SELECT 
    tm.title,
    tm.production_year,
    tm.cast_count,
    tm.avg_rating,
    COALESCE(cm.company_names, 'Not Available') AS companies
FROM 
    top_movies AS tm
LEFT JOIN 
    company_movies AS cm ON tm.movie_id = cm.movie_id
ORDER BY 
    tm.production_year DESC, 
    tm.avg_rating DESC;
