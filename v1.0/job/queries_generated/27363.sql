WITH movie_ratings AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        AVG(COALESCE(r.rating, 0)) AS avg_rating
    FROM 
        title t
    LEFT JOIN 
        movie_info mi ON t.id = mi.movie_id AND mi.info_type_id = (
            SELECT id FROM info_type WHERE info = 'rating'
        )
    LEFT JOIN 
        (SELECT movie_id, 
                (CASE 
                    WHEN info IS NOT NULL THEN CAST(info AS FLOAT) 
                    ELSE NULL 
                 END) AS rating 
         FROM movie_info) r ON t.id = r.movie_id
    GROUP BY 
        t.id
),
actor_movie AS (
    SELECT 
        ci.movie_id,
        ak.name AS actor_name,
        ak.imdb_index AS actor_index,
        COUNT(*) AS role_count
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        ci.movie_id, ak.name, ak.imdb_index
),
high_rating_movies AS (
    SELECT 
        mr.title,
        mr.production_year,
        mr.avg_rating,
        am.actor_name,
        am.role_count
    FROM 
        movie_ratings mr
    JOIN 
        actor_movie am ON mr.title_id = am.movie_id
    WHERE 
        mr.avg_rating >= 8.0
)
SELECT 
    hr.title,
    hr.production_year,
    hr.avg_rating,
    hr.actor_name,
    hr.role_count
FROM 
    high_rating_movies hr
ORDER BY 
    hr.avg_rating DESC, 
    hr.production_year DESC;
