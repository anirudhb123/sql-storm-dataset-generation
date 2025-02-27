WITH RecursiveActorInfo AS (
    SELECT 
        ka.name AS actor_name,
        c.movie_id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY ka.name) AS actor_rank,
        COUNT(*) OVER (PARTITION BY c.movie_id) AS actor_count
    FROM 
        aka_name ka
    JOIN 
        cast_info c ON ka.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    WHERE 
        ka.name IS NOT NULL
),

MovieDetail AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        COALESCE(AVG(r.rating), 0) AS average_rating,
        COUNT(DISTINCT mk.keyword) AS keyword_count
    FROM 
        aka_title m
    LEFT JOIN 
        movie_info mi ON m.id = mi.movie_id
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        (SELECT 
             movie_id, 
             AVG(rating) AS rating 
         FROM 
             movie_info 
         WHERE 
             info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
         GROUP BY 
             movie_id) r ON m.id = r.movie_id
    GROUP BY 
        m.id
),

EnhancedJoin AS (
    SELECT 
        m.movie_id,
        m.movie_title,
        m.average_rating,
        m.keyword_count,
        ai.actor_name,
        ai.actor_rank,
        a.actor_count
    FROM 
        MovieDetail m
    LEFT JOIN 
        RecursiveActorInfo ai ON m.movie_id = ai.movie_id
    LEFT JOIN 
        (SELECT DISTINCT movie_id, COUNT(actor_name) OVER (PARTITION BY movie_id) AS actor_count 
         FROM RecursiveActorInfo) a ON m.movie_id = a.movie_id
    WHERE 
        m.average_rating > 0 OR ai.actor_name IS NOT NULL
)

SELECT 
    e.movie_id,
    e.movie_title,
    e.average_rating,
    e.keyword_count,
    CASE 
        WHEN e.average_rating IS NULL THEN 'No Rating'
        WHEN e.average_rating < 5 THEN 'Low'
        WHEN e.average_rating >= 5 AND e.average_rating < 8 THEN 'Medium'
        ELSE 'High'
    END AS rating_category,
    STRING_AGG(e.actor_name, ', ') AS list_of_actors,
    COALESCE(MAX(e.actor_rank), 0) AS max_actor_rank,
    COUNT(DISTINCT e.movie_id) OVER () AS total_movies
FROM 
    EnhancedJoin e
GROUP BY 
    e.movie_id, e.movie_title, e.average_rating, e.keyword_count
ORDER BY 
    e.average_rating DESC NULLS LAST, 
    e.movie_title
LIMIT 10 OFFSET 5;
