
WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS movie_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
cast_summary AS (
    SELECT 
        c.movie_id,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names,
        COUNT(DISTINCT a.id) AS number_of_actors,
        SUM(CASE WHEN a.id IS NOT NULL THEN 1 ELSE 0 END) AS actor_count
    FROM 
        cast_info c
    LEFT JOIN 
        aka_name a ON a.person_id = c.person_id
    GROUP BY 
        c.movie_id
),
genre_summary AS (
    SELECT 
        m.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS genres
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON k.id = mk.keyword_id
    JOIN 
        aka_title m ON m.id = mk.movie_id
    GROUP BY 
        m.movie_id
),
final_summary AS (
    SELECT 
        rm.title,
        rm.production_year,
        cs.actor_names,
        cs.number_of_actors,
        gs.genres,
        COALESCE(cs.actor_count, 0) AS total_actors,
        CASE 
            WHEN rm.production_year IS NOT NULL AND rm.movie_rank <= 10 THEN 'Top Releases'
            ELSE 'Other Releases'
        END AS release_category
    FROM 
        ranked_movies rm
    LEFT JOIN 
        cast_summary cs ON cs.movie_id = rm.movie_id
    LEFT JOIN 
        genre_summary gs ON gs.movie_id = rm.movie_id
)
SELECT 
    title,
    production_year,
    actor_names,
    number_of_actors,
    genres,
    total_actors,
    release_category
FROM 
    final_summary
WHERE 
    (production_year >= 2000 AND number_of_actors > 5) OR 
    (production_year < 2000 AND genres IS NOT NULL)
ORDER BY 
    production_year DESC,
    title ASC;
