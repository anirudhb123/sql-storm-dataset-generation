WITH RankedMovies AS (
    SELECT 
        at.id AS movie_id,
        at.title,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS ranking,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM 
        aka_title at
    LEFT JOIN 
        cast_info ci ON at.movie_id = ci.movie_id
    WHERE 
        at.production_year IS NOT NULL
    GROUP BY 
        at.id, at.title, at.production_year
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        cast_count
    FROM 
        RankedMovies
    WHERE 
        ranking <= 5
),
MovieDetails AS (
    SELECT 
        tm.movie_id,
        tm.title,
        ARRAY_AGG(DISTINCT ak.name) AS actors,
        STRING_AGG(DISTINCT mk.keyword, ', ') AS keywords
    FROM 
        TopMovies tm
    LEFT JOIN 
        cast_info ci ON tm.movie_id = ci.movie_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        movie_keyword mk ON tm.movie_id = mk.movie_id
    GROUP BY 
        tm.movie_id, tm.title
)
SELECT 
    md.movie_id,
    md.title,
    md.actors,
    COALESCE(md.keywords, 'No keywords') AS keywords,
    CASE 
        WHEN md.actors IS NOT NULL THEN ARRAY_LENGTH(md.actors, 1) 
        ELSE 0 
    END AS total_actors,
    (SELECT COUNT(*)
     FROM complete_cast cc
     WHERE cc.movie_id = md.movie_id
       AND cc.status_id IS NOT NULL) AS complete_cast_count,
    (SELECT STRING_AGG(DISTINCT ci.note, '; ') 
     FROM cast_info ci 
     WHERE ci.movie_id = md.movie_id 
       AND ci.note IS NOT NULL AND ci.note <> ''
    ) AS notes
FROM 
    MovieDetails md
ORDER BY 
    md.cast_count DESC NULLS LAST, 
    md.title ASC;

### Explanation of the Query:

1. **CTEs Definition**:
   - `RankedMovies`: This CTE ranks movies per production year based on the number of distinct cast members. The `ROW_NUMBER()` window function is used to assign a rank.
   - `TopMovies`: Filters the top 5 movies from each production year based on their cast count.
   - `MovieDetails`: Joins the `TopMovies` with `aka_name` and `movie_keyword` to gather the names of actors and keywords associated with each movie.

2. **Main Query**:
   - Selects the relevant details from `MovieDetails`, including a list of actors and keywords. String aggregation is used for collecting keywords.
   - Uses `COALESCE` to provide a fallback value for keywords if none exist.
   - Computes the total number of actors using `ARRAY_LENGTH`.
   - Utilizes a correlated subquery to count the `complete_cast` for each movie.
   - Another subquery aggregates notes associated with cast information.

3. **Ordering and Display**:
   - Final results are ordered by the highest cast count and then by movie title in ascending order. Results with no actors appear last.

This query employs outer joins, window functions, subqueries, aggregate functions, and complex conditional expressions to create a comprehensive and performance-benchmarked view of top movies, their casts, and associated metadata.
