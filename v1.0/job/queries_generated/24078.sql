WITH ranked_movies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        ROW_NUMBER() OVER (PARTITION BY mt.kind_id ORDER BY mt.production_year DESC) AS rank_within_kind
    FROM 
        aka_title mt
    INNER JOIN 
        movie_keyword mk ON mk.movie_id = mt.movie_id
    WHERE 
        mk.keyword_id IN (SELECT id FROM keyword WHERE keyword IN ('Drama', 'Action'))
),
unique_actors AS (
    SELECT 
        DISTINCT ca.person_id,
        an.name,
        COUNT(DISTINCT ci.movie_id) AS movies_count
    FROM 
        cast_info ci
    JOIN 
        aka_name an ON an.person_id = ci.person_id
    LEFT JOIN 
        ranked_movies rm ON rm.movie_id = ci.movie_id
    WHERE 
        rm.rank_within_kind = 1
    GROUP BY 
        ca.person_id, an.name
    HAVING 
        COUNT(DISTINCT ci.movie_id) > 3
),
total_movies AS (
    SELECT 
        COUNT(*) AS total_count
    FROM 
        aka_title
),
actors_with_movie_count AS (
    SELECT 
        ua.name,
        ua.movies_count,
        (SELECT total_count FROM total_movies) AS total_movies_count,
        (ua.movies_count::float / (SELECT total_count FROM total_movies)) * 100 AS percentage_of_total
    FROM 
        unique_actors ua
)
SELECT 
    a.name AS actor_name,
    a.movies_count,
    a.total_movies_count,
    a.percentage_of_total,
    CASE 
        WHEN a.percentage_of_total > 10 THEN 'Highly Active Actor'
        WHEN a.percentage_of_total BETWEEN 5 AND 10 THEN 'Moderately Active Actor'
        ELSE 'Less Active Actor'
    END AS activity_category
FROM 
    actors_with_movie_count a
ORDER BY 
    a.percentage_of_total DESC
LIMIT 10;

