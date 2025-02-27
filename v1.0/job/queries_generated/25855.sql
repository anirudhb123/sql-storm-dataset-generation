WITH movie_actors AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    GROUP BY 
        c.movie_id, a.name, t.title, t.production_year
),
keyword_summary AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
info_summary AS (
    SELECT 
        mi.movie_id,
        STRING_AGG(DISTINCT mi.info, '; ') AS info_details
    FROM 
        movie_info mi
    GROUP BY 
        mi.movie_id
)
SELECT 
    ma.movie_id,
    ma.movie_title,
    ma.production_year,
    ma.actor_name,
    ma.actor_count,
    ks.keywords,
    is.info_details
FROM 
    movie_actors ma
LEFT JOIN 
    keyword_summary ks ON ma.movie_id = ks.movie_id
LEFT JOIN 
    info_summary is ON ma.movie_id = is.movie_id
WHERE 
    ma.production_year >= 2000
ORDER BY 
    ma.production_year DESC, 
    ma.actor_count DESC
LIMIT 50;

This SQL query creates a comprehensive view of movies produced since 2000, additionally providing details on the actors involved, the total actor count per movie, keywords associated with each movie, and any related information summaries. The result set is ordered by the production year (latest first) and then by the number of actors involved in the movie. The use of Common Table Expressions (CTEs) makes the query organized and efficient for string processing benchmarks.
