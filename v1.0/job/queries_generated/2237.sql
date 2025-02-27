WITH movie_ratings AS (
    SELECT 
        m.id AS movie_id,
        AVG(r.rating) AS avg_rating
    FROM 
        title m
    LEFT JOIN 
        movie_info mi ON m.id = mi.movie_id
    LEFT JOIN 
        (SELECT movie_id, rating FROM movie_ratings_table) r ON m.id = r.movie_id
    GROUP BY 
        m.id
),
actor_info AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        COUNT(DISTINCT c.movie_id) AS movie_count
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    GROUP BY 
        a.id, a.name
),
high_rated_movies AS (
    SELECT 
        mr.movie_id
    FROM 
        movie_ratings mr
    WHERE 
        mr.avg_rating > 8.0
),
trending_movies AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        COALESCE(r.avg_rating, 0) AS avg_rating,
        COALESCE(ai.movie_count, 0) AS actor_count
    FROM 
        title m
    LEFT JOIN 
        movie_ratings r ON m.id = r.movie_id
    LEFT JOIN 
        cast_info c ON m.id = c.movie_id
    LEFT JOIN 
        actor_info ai ON c.person_id = ai.actor_id
    WHERE 
        m.production_year >= 2020
    ORDER BY 
        avg_rating DESC,
        actor_count DESC
)
SELECT 
    tm.movie_title,
    tm.avg_rating,
    tm.actor_count,
    (SELECT COUNT(*) FROM movie_keyword mk WHERE mk.movie_id = tm.movie_id) AS keyword_count
FROM 
    trending_movies tm
WHERE 
    tm.movie_id IN (SELECT movie_id FROM high_rated_movies)
ORDER BY 
    tm.avg_rating DESC, 
    keyword_count DESC
LIMIT 10;
