WITH RankedMovies AS (
    SELECT 
        movie_id, 
        title, 
        production_year,
        ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY COUNT(cast_info.id) DESC) AS movie_rank
    FROM 
        aka_title 
    JOIN 
        movie_info ON aka_title.movie_id = movie_info.movie_id
    LEFT JOIN 
        cast_info ON movie_info.movie_id = cast_info.movie_id
    GROUP BY 
        movie_id, title, production_year
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year
    FROM 
        RankedMovies
    WHERE 
        movie_rank <= 5
),
MovieDetails AS (
    SELECT 
        tm.title AS movie_title,
        tm.production_year,
        STRING_AGG(DISTINCT an.name, ', ') AS actor_names,
        c.name AS company_name,
        CASE 
            WHEN COUNT(DISTINCT an.id) > 5 THEN 'Ensemble Cast'
            ELSE 'Small Cast'
        END AS cast_size_description
    FROM 
        TopMovies tm
    LEFT JOIN 
        complete_cast cc ON tm.movie_id = cc.movie_id
    LEFT JOIN 
        aka_name an ON cc.subject_id = an.person_id
    LEFT JOIN 
        movie_companies mc ON tm.movie_id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    GROUP BY 
        tm.movie_id, tm.title, tm.production_year, c.name
),
FilteredMovies AS (
    SELECT 
        *, 
        CASE 
            WHEN production_year IS NULL THEN 'Unknown Year'
            ELSE production_year::TEXT 
        END AS year_display
    FROM 
        MovieDetails
    WHERE 
        company_name IS NOT NULL
)
SELECT 
    movie_title,
    year_display,
    actor_names,
    cast_size_description,
    COALESCE(company_name, 'Independent') AS production_company
FROM 
    FilteredMovies
WHERE 
    actor_names IS NOT NULL
ORDER BY 
    production_year DESC, movie_title ASC;

-- Corner Cases exploration with NULL logic handling
UNION ALL

SELECT 
    'N/A' AS movie_title,
    'N/A' AS year_display,
    NULL AS actor_names,
    'N/A' AS cast_size_description,
    'Independent' AS production_company
WHERE 
    NOT EXISTS (SELECT 1 FROM FilteredMovies);

This SQL query performs the following:

1. **Common Table Expressions (CTEs)**: Uses CTEs for organizing the logic, including ranking movies by the number of cast members and filtering for the top five based on production year.
2. **Window Functions**: Applies `ROW_NUMBER` to rank movies within the same production year based on the number of cast members.
3. **String Aggregation**: Utilizes `STRING_AGG` to combine actor names into a single string.
4. **Conditional Case**: Implements a `CASE` statement to classify the cast size.
5. **NULL Handling**: Incorporates `COALESCE` to handle potential NULL values in the production company and provides default values.
6. **Set Operators**: Utilizes a UNION ALL to handle corner cases where no movies exist after filtering (returning a placeholder entry).
7. **Unusual Logic**: Filters based on both NULL and non-NULL conditions for various scenarios throughout the query.

This comprehensive approach not only benchmarks performance but also demonstrates advanced SQL concepts, catering to various peculiarities in SQL semantics.
