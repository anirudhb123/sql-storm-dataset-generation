WITH movie_ratings AS (
    SELECT 
        m.id AS movie_id,
        AVG(r.rating) AS avg_rating,
        COUNT(r.id) AS rating_count
    FROM 
        title m
    LEFT JOIN 
        movie_info m_info ON m.id = m_info.movie_id AND m_info.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
    LEFT JOIN 
        (SELECT movie_id, rating FROM ratings WHERE year > 2000) r ON m.id = r.movie_id
    GROUP BY 
        m.id
),
actor_movie_counts AS (
    SELECT 
        c.person_id,
        COUNT(DISTINCT c.movie_id) AS movie_count
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        c.person_id
),
top_actors AS (
    SELECT 
        a.person_id,
        a.name AS actor_name,
        COUNT(*) AS total_movies
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    GROUP BY 
        a.person_id, a.name
    HAVING 
        COUNT(*) > 10
),
detailed_movie_info AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COALESCE(mr.avg_rating, 0) AS avg_rating,
        CASE 
            WHEN mr.rating_count = 0 THEN 'No Ratings'
            ELSE 'Rated'
        END AS rating_status,
        kc.keyword AS keyword
    FROM 
        title t
    LEFT JOIN 
        movie_ratings mr ON t.id = mr.movie_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword kc ON mk.keyword_id = kc.id
),
actor_movie_details AS (
    SELECT 
        dmi.movie_id,
        dmi.title,
        dmi.production_year,
        dmi.avg_rating,
        dmi.rating_status,
        a.actor_name,
        ac.movie_count
    FROM 
        detailed_movie_info dmi
    JOIN 
        cast_info c ON dmi.movie_id = c.movie_id
    JOIN 
        top_actors a ON c.person_id = a.person_id
    JOIN 
        actor_movie_counts ac ON a.person_id = ac.person_id
)
SELECT 
    amd.movie_id,
    amd.title,
    amd.production_year,
    amd.avg_rating,
    amd.rating_status,
    amd.actor_name,
    amd.movie_count
FROM 
    actor_movie_details amd
WHERE 
    amd.avg_rating >= (
        SELECT 
            AVG(avg_rating)
        FROM 
            movie_ratings
    )
ORDER BY 
    amd.avg_rating DESC, amd.title ASC
LIMIT 10;

This SQL query builds a comprehensive analysis involving movies, ratings, actors, and keywords, utilizing multiple CTEs, aggregate functions, and various SQL constructs to derive insightful results about the highest-rated movies featuring prolific actors.
