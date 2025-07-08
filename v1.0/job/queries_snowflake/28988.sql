
WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT m.id) AS company_count,
        LISTAGG(DISTINCT c.name, ', ') WITHIN GROUP (ORDER BY c.name) AS company_names,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT m.id) DESC) AS rn
    FROM 
        aka_title t
    JOIN 
        movie_companies m ON t.id = m.movie_id
    JOIN 
        company_name c ON m.company_id = c.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
),
top_rated_movies AS (
    SELECT 
        mt.movie_id,
        mt.title,
        mt.production_year,
        pi.info AS average_rating
    FROM 
        ranked_movies mt
    LEFT JOIN 
        movie_info pi ON mt.movie_id = pi.movie_id AND pi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
    WHERE 
        mt.rn <= 10
)
SELECT 
    m.movie_id,
    m.title,
    m.production_year,
    m.average_rating,
    rn.company_count,
    rn.company_names
FROM 
    top_rated_movies m
JOIN 
    ranked_movies rn ON m.movie_id = rn.movie_id
ORDER BY 
    m.production_year DESC, 
    m.average_rating DESC;
