WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS actor_count_rank
    FROM 
        aka_title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
), 
actor_stats AS (
    SELECT 
        a.person_id,
        a.name,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        AVG(YEAR(current_date) - t.production_year) AS avg_movie_age
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        aka_title t ON ci.movie_id = t.id
    GROUP BY 
        a.person_id, a.name
),
movie_info_aggregated AS (
    SELECT 
        m.id AS movie_id,
        COUNT(k.keyword) AS keyword_count,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        MAX(mp.info) AS longest_info_note
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_info mp ON m.id = mp.movie_id
    GROUP BY 
        m.id
)
SELECT 
    m.title,
    m.production_year,
    COALESCE(as.movie_count, 0) AS total_actors,
    COALESCE(ma.keywords, 'No Keywords') AS keywords,
    COALESCE(ma.longest_info_note, 'No Info') AS longest_info_note,
    mr.actor_count_rank 
FROM 
    ranked_movies mr
JOIN 
    movie_info_aggregated ma ON mr.movie_id = ma.movie_id
LEFT JOIN 
    actor_stats as ON mr.movie_id IN (SELECT movie_id FROM cast_info WHERE person_id = as.person_id)
WHERE 
    mr.actor_count_rank <= 5 
    AND (m.title ILIKE '%comedy%' OR ma.keyword_count > 2) 
ORDER BY 
    mr.production_year DESC, 
    total_actors DESC, 
    m.title;

-- The above query does the following:
-- 1. Ranks movies by the number of distinct actors each movie has, grouped by production year.
-- 2. Computes actor statistics including the number of movies they acted in and the average age since those movies were produced.
-- 3. Aggregates movie info to count the number of associated keywords and find the longest note for each movie.
-- 4. Selects from the ranked movie data, joining with aggregated movie info and actor stats.
-- 5. Filters to include only movies in the top 5 ranked by actor count and either labeled as 'comedy' or having more than 2 keywords, ensuring complex predicate usage.
-- 6. Orders the final selection by production year, total actors, and title for better readability.
