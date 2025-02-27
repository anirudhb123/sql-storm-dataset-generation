-- This SQL query benchmarks string processing by retrieving detailed information about movies,
-- their titles, associated actors, and production companies that contain specific keywords
-- in the title or actor names. The query filters movies from the last decade, groups them 
-- by production year, and calculates the number of titles and unique actors involved each year.

WITH MovieDetails AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        a.name AS actor_name,
        c.name AS company_name,
        k.keyword
    FROM 
        title t
    JOIN 
        movie_info mi ON t.id = mi.movie_id
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ca ON cc.subject_id = ca.person_id
    JOIN 
        aka_name a ON ca.person_id = a.person_id
    WHERE 
        t.production_year >= EXTRACT(YEAR FROM CURRENT_DATE) - 10
        AND (t.title ILIKE '%adventure%' OR a.name ILIKE '%Smith%')
)

SELECT 
    production_year,
    COUNT(DISTINCT title_id) AS total_titles,
    COUNT(DISTINCT actor_name) AS unique_actors,
    STRING_AGG(DISTINCT title, '; ') AS titles_list,
    STRING_AGG(DISTINCT actor_name, ', ') AS actors_list,
    STRING_AGG(DISTINCT company_name, ', ') AS companies_list
FROM 
    MovieDetails
GROUP BY 
    production_year
ORDER BY 
    production_year DESC;

This query accomplishes the following:
- It uses Common Table Expressions (CTEs) to simplify the main query.
- It filters for movies produced within the last decade and titles or actor names that contain specific keywords.
- It aggregates results to provide a count of unique titles and actors per production year and concatenates lists of titles and names for easy reading.
- It organizes the output by the production year in descending order to highlight more recent movies.
