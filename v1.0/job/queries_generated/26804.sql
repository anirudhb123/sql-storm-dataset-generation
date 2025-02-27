WITH RankedMovies AS (
    SELECT 
        at.id AS title_id,
        at.title,
        at.production_year,
        COUNT(ci.person_id) AS cast_count,
        ARRAY_AGG(DISTINCT ak.name) AS aka_names,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank
    FROM 
        aka_title at
    LEFT JOIN 
        cast_info ci ON at.movie_id = ci.movie_id
    LEFT JOIN 
        aka_name ak ON ak.person_id = ci.person_id
    GROUP BY 
        at.id, at.title, at.production_year
), FilteredMovies AS (
    SELECT 
        title_id,
        title,
        production_year,
        cast_count,
        aka_names
    FROM 
        RankedMovies
    WHERE 
        rank <= 5 -- Top 5 movies per year
)

SELECT 
    fm.production_year,
    COUNT(fm.title_id) AS total_movies,
    STRING_AGG(fm.title, ', ') AS movie_titles,
    STRING_AGG(UNNEST(fm.aka_names), ', ') AS all_aka_names
FROM 
    FilteredMovies fm
GROUP BY 
    fm.production_year
ORDER BY 
    fm.production_year DESC;

This SQL query accomplishes the following:
1. It first creates a Common Table Expression (CTE) `RankedMovies` to calculate the number of cast members in each movie, grouping by movie titles while also aggregating alternate names (aka_names).
2. It ranks the movies by production year and count of cast members.
3. Then it further filters the results to include only the top 5 movies from each production year into another CTE `FilteredMovies`.
4. Finally, it aggregates the results to get total movies produced each year, alongside a concatenated list of movie titles and all associated alternate names, ordered by the most recent production year.
