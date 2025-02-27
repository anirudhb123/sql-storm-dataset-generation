WITH ranked_movies AS (
    SELECT 
        mt.title, 
        mt.production_year,
        COUNT(DISTINCT mc.company_id) AS company_count,
        RANK() OVER (PARTITION BY mt.production_year ORDER BY COUNT(DISTINCT mc.company_id) DESC) AS rank
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_companies mc ON mt.id = mc.movie_id
    GROUP BY 
        mt.id, mt.title, mt.production_year
), high_production_years AS (
    SELECT 
        production_year
    FROM 
        ranked_movies
    WHERE 
        rank <= 5
), actor_info AS (
    SELECT 
        a.name AS actor_name, 
        COUNT(DISTINCT c.movie_id) AS movie_count,
        SUM(CASE WHEN c.nr_order IS NULL THEN 1 ELSE 0 END) AS unknown_order_count
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    WHERE 
        a.id IN (SELECT DISTINCT person_id FROM person_info WHERE info_type_id = (SELECT id FROM info_type WHERE info = 'birth date'))
    GROUP BY 
        a.name
), movies_details AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        COALESCE(m.rating, 'Not Rated') AS movie_rating,
        COALESCE((SELECT AVG(r.rating) FROM movie_info r WHERE r.movie_id = m.id), 0) AS average_rating
    FROM 
        aka_title m
    LEFT JOIN 
        movie_info mi ON m.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
    WHERE 
        m.production_year IN (SELECT production_year FROM high_production_years)
)
SELECT 
    md.movie_id, 
    md.title, 
    md.movie_rating, 
    ai.actor_name, 
    ai.movie_count, 
    ai.unknown_order_count 
FROM 
    movies_details md
JOIN 
    cast_info ci ON md.movie_id = ci.movie_id
JOIN 
    aka_name an ON ci.person_id = an.person_id
JOIN 
    actor_info ai ON an.name = ai.actor_name
WHERE 
    md.average_rating > 5 
ORDER BY 
    md.production_year DESC, ai.movie_count DESC;
