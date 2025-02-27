WITH ranked_movies AS (
    SELECT 
        title.id AS movie_id,
        title.title,
        title.production_year,
        ROW_NUMBER() OVER (PARTITION BY title.production_year ORDER BY COUNT(cast_info.id) DESC) AS rank
    FROM 
        title
    LEFT JOIN 
        cast_info ON title.id = cast_info.movie_id
    GROUP BY 
        title.id, title.title, title.production_year
),
actor_names AS (
    SELECT 
        aka_name.person_id,
        STRING_AGG(DISTINCT aka_name.name, ', ') AS names
    FROM 
        aka_name
    GROUP BY 
        aka_name.person_id
),
high_rating_movies AS (
    SELECT 
        movie_info.movie_id,
        SUM(CASE WHEN movie_info.info_type_id = (SELECT id FROM info_type WHERE info = 'rating') THEN movie_info.info::float ELSE 0 END) AS total_rating
    FROM 
        movie_info
    GROUP BY 
        movie_info.movie_id
    HAVING 
        SUM(CASE WHEN movie_info.info_type_id = (SELECT id FROM info_type WHERE info = 'rating') THEN movie_info.info::float ELSE 0 END) >= 8.0
)

SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    COALESCE(an.names, 'Unknown Actor') AS actor_names,
    h.total_rating
FROM 
    ranked_movies rm
LEFT JOIN 
    high_rating_movies h ON rm.movie_id = h.movie_id
LEFT JOIN 
    cast_info ci ON rm.movie_id = ci.movie_id
LEFT JOIN 
    actor_names an ON ci.person_id = an.person_id
WHERE 
    rm.rank <= 5
ORDER BY 
    rm.production_year DESC,
    h.total_rating DESC NULLS LAST;
