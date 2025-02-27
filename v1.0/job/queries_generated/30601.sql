WITH RECURSIVE popular_movies AS (
    SELECT 
        mt.title AS movie_title,
        COUNT(mci.person_id) AS cast_count,
        mt.production_year
    FROM 
        aka_title mt
    JOIN 
        movie_companies mc ON mt.id = mc.movie_id
    JOIN 
        movie_info mi ON mt.id = mi.movie_id
    JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    LEFT JOIN 
        cast_info c ON mt.id = c.movie_id
    WHERE 
        mi.info_type_id = (SELECT id FROM info_type WHERE info = 'duration') 
        AND mi.info IS NOT NULL 
        AND mt.production_year BETWEEN 2000 AND 2020
    GROUP BY 
        mt.title, mt.production_year
    HAVING 
        COUNT(c.person_id) > 5
),
company_movie_counts AS (
    SELECT 
        cn.name AS company_name,
        COUNT(m.id) AS movie_count
    FROM 
        company_name cn
    JOIN 
        movie_companies mc ON cn.id = mc.company_id
    JOIN 
        aka_title m ON mc.movie_id = m.id
    WHERE 
        cn.country_code = 'USA'
    GROUP BY 
        cn.name
),
highest_rated_titles AS (
    SELECT 
        mt.title AS movie_title,
        ROUND(AVG(mi.info::numeric), 2) AS average_rating
    FROM 
        aka_title mt
    JOIN 
        movie_info mi ON mt.id = mi.movie_id
    WHERE 
        mi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
    GROUP BY 
        mt.title
    HAVING 
        AVG(mi.info::numeric) > 7.0
)
SELECT 
    pm.movie_title,
    pm.production_year,
    c.movie_count,
    hrt.average_rating
FROM 
    popular_movies pm
LEFT JOIN 
    company_movie_counts c ON c.movie_count = 
        (SELECT MAX(movie_count) FROM company_movie_counts)
LEFT JOIN 
    highest_rated_titles hrt ON pm.movie_title = hrt.movie_title
WHERE 
    c.movie_count IS NOT NULL
ORDER BY 
    pm.cast_count DESC, pm.production_year;
