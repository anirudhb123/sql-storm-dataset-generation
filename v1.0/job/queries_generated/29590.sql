WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names
    FROM 
        aka_title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        t.id, t.title, t.production_year
),
PopularMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.cast_count,
        rm.actor_names,
        RANK() OVER (ORDER BY rm.cast_count DESC) AS rank
    FROM 
        RankedMovies rm
    WHERE 
        rm.production_year >= 2000 AND rm.production_year <= 2023
)
SELECT 
    pm.movie_id,
    pm.title,
    pm.production_year,
    pm.cast_count,
    pm.actor_names
FROM 
    PopularMovies pm
WHERE 
    pm.rank <= 10
ORDER BY 
    pm.rank;

This SQL query benchmarks string processing by aggregating actors' names for movies from the `aka_title`, `cast_info`, and `aka_name` tables. It retrieves the top 10 movies by the number of distinct actors involved, limited to those released between 2000 and 2023. The output includes movie IDs, titles, production years, cast counts, and concatenated actor names, demonstrating effective string aggregation and ranking functionalities.
