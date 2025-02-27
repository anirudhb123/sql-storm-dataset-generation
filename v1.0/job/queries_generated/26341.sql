WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank_within_year
    FROM 
        aka_title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        t.production_year IS NOT NULL
        AND t.title IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),

TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        total_cast,
        cast_names
    FROM 
        RankedMovies
    WHERE 
        rank_within_year <= 3
)

SELECT 
    t.production_year,
    STRING_AGG(t.title, '; ') AS top_titles,
    STRING_AGG(t.cast_names, '; ') AS cast_lists
FROM 
    TopMovies t
GROUP BY 
    t.production_year
ORDER BY 
    t.production_year DESC;

This query does the following:

1. Creates a common table expression (CTE) called `RankedMovies` which retrieves the movie ID, title, production year, total count of distinct cast members, and a concatenated list of their names for each movie. It also ranks the movies within each production year based on the total cast count.

2. Creates another CTE called `TopMovies` that filters for the top 3 ranked movies for each production year.

3. The final select statement aggregates the top movie titles and their respective cast lists by production year, ordering the results by production year in descending order. This allows for an efficient way of analyzing string processing related to movie titles and cast members across different years.
