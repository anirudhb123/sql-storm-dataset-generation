WITH movie_info_details AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        ARRAY_AGG(DISTINCT CONCAT('Genre: ', g.kind)) AS genres,
        AVG(r.rating) AS average_rating
    FROM 
        title AS m
    LEFT JOIN 
        kind_type AS g ON m.kind_id = g.id
    LEFT JOIN 
        movie_info AS mi ON m.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
    LEFT JOIN 
        (SELECT movie_id, AVG(CAST(info AS FLOAT)) AS rating 
         FROM movie_info 
         WHERE info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
         GROUP BY movie_id) AS r ON m.id = r.movie_id
    GROUP BY 
        m.id, m.title
), 
actor_info AS (
    SELECT 
        a.person_id,
        a.name,
        ARRAY_AGG(DISTINCT m.movie_id) AS movies,
        COUNT(DISTINCT m.movie_id) AS movie_count
    FROM 
        aka_name AS a
    JOIN 
        cast_info AS c ON a.person_id = c.person_id
    JOIN 
        title AS m ON c.movie_id = m.id
    GROUP BY 
        a.person_id, a.name
), 
company_info AS (
    SELECT 
        co.id AS company_id,
        co.name AS company_name,
        COUNT(DISTINCT mc.movie_id) AS movie_count,
        STRING_AGG(DISTINCT t.title, ', ') AS movies
    FROM 
        company_name AS co
    JOIN 
        movie_companies AS mc ON co.id = mc.company_id
    JOIN 
        title AS t ON mc.movie_id = t.id
    GROUP BY 
        co.id, co.name
)
SELECT 
    m.movie_title,
    m.genres,
    m.average_rating,
    a.name AS actor_name,
    a.movie_count AS actor_movie_count,
    c.company_name,
    c.movie_count AS company_movie_count,
    c.movies AS company_movies
FROM 
    movie_info_details AS m
JOIN 
    actor_info AS a ON a.movies && m.movie_id
JOIN 
    company_info AS c ON c.movie_count > 0
ORDER BY 
    m.average_rating DESC, a.movie_count DESC;
