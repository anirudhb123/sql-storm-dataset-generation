WITH movie_summary AS (
    SELECT 
        mt.title AS movie_title,
        mt.production_year,
        AVG(ki.rating) AS average_rating,
        ARRAY_AGG(DISTINCT cn.name) AS production_companies,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM 
        aka_title mt
    JOIN 
        movie_info mi ON mt.id = mi.movie_id
    JOIN 
        movie_companies mc ON mt.id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        complete_cast cc ON mt.id = cc.movie_id
    JOIN 
        cast_info ci ON ci.movie_id = mt.id
    LEFT JOIN 
        (SELECT movie_id, AVG(rating) AS rating FROM movie_info WHERE info_type_id = (SELECT id FROM info_type WHERE info = 'rating') GROUP BY movie_id) ki ON mt.id = ki.movie_id
    WHERE 
        mt.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        mt.title, mt.production_year
)
SELECT 
    movie_title, 
    production_year, 
    average_rating, 
    cast_count, 
    ARRAY_TO_STRING(production_companies, ', ') AS production_company_list
FROM 
    movie_summary
ORDER BY 
    production_year DESC, average_rating DESC
LIMIT 10;
