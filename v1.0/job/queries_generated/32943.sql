WITH RecursiveMovieCast AS (
    SELECT 
        ci.movie_id,
        ci.person_id,
        ca.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS role_rank
    FROM 
        cast_info ci
    JOIN 
        aka_name ca ON ci.person_id = ca.person_id
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(mk.keyword_id::TEXT, ', ') AS keywords
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
),
ProductionYearMovies AS (
    SELECT 
        title.id AS title_id,
        title.title,
        title.production_year
    FROM 
        title 
    WHERE 
        title.production_year > 2000
),
DetailedMovieInfo AS (
    SELECT 
        pmm.movie_id,
        pm.person_id,
        pm.info,
        pm.note
    FROM 
        movie_info pmm
    JOIN 
        person_info pm ON pmm.movie_id = pm.person_id
    WHERE 
        pm.note IS NOT NULL
),
RankedMovies AS (
    SELECT
        tm.title,
        tm.production_year,
        COUNT(DISTINCT cm.person_id) AS total_actors,
        COALESCE(mk.keywords, 'No Keywords') AS keywords
    FROM 
        ProductionYearMovies tm
    LEFT JOIN 
        RecursiveMovieCast cm ON tm.title_id = cm.movie_id
    LEFT JOIN 
        MovieKeywords mk ON tm.title_id = mk.movie_id
    GROUP BY 
        tm.title_id, tm.title, tm.production_year
    HAVING 
        COUNT(DISTINCT cm.person_id) > 5
)
SELECT 
    R.title,
    R.production_year,
    R.total_actors,
    R.keywords
FROM 
    RankedMovies R
ORDER BY 
    R.production_year DESC, R.total_actors DESC;
This SQL query performs the following tasks:

1. **Recursive CTE**: `RecursiveMovieCast` retrieves the movie ID and associated actor names, assigning a rank to each actor based on their order in the cast list.
   
2. **Aggregate Function**: `MovieKeywords` collects keywords associated with each movie using `STRING_AGG` to concatenate them into a single string.

3. **Filtering**: `ProductionYearMovies` selects movies produced after the year 2000.

4. **JOIN Operations**: The `DetailedMovieInfo` CTE attempts to join movie info with person info based on person IDs while ensuring the notes are non-null.

5. **LEFT JOIN**: The final `RankedMovies` CTE counts the number of distinct actors per movie that match the filtering criteria and gathers keywords.

6. **HAVING Clause**: Filters for movies with more than five actors.

7. **Final Selection and Ordering**: The main SELECT pulls data from `RankedMovies`, ordering results by production year and total number of actors. 

This query demonstrates extensive use of advanced SQL features suitable for performance benchmarking in a relational database.
