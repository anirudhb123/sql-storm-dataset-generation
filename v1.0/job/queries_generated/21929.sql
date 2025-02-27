WITH RankedMovies AS (
    SELECT 
        at.title,
        at.production_year,
        COUNT(DISTINCT ci.person_id) OVER (PARTITION BY at.movie_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') FILTER (WHERE ak.name IS NOT NULL) AS actors,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS year_rank
    FROM 
        aka_title at
    LEFT JOIN 
        cast_info ci ON ci.movie_id = at.movie_id
    LEFT JOIN 
        aka_name ak ON ak.person_id = ci.person_id
    WHERE 
        at.production_year IS NOT NULL
    GROUP BY 
        at.movie_id, at.title, at.production_year
),

HighlightedMovies AS (
    SELECT 
        title, 
        production_year, 
        cast_count,
        actors,
        CASE 
            WHEN cast_count > 5 THEN 'Popular'
            ELSE 'Less Known'
        END AS movie_type
    FROM 
        RankedMovies
    WHERE 
        year_rank <= 5
),

MovieKeywords AS (
    SELECT 
        at.title,
        mk.keyword
    FROM 
        aka_title at
    JOIN 
        movie_keyword mk ON at.movie_id = mk.movie_id
    WHERE 
        mk.keyword IS NOT NULL
)

SELECT 
    hm.title,
    hm.production_year,
    hm.cast_count,
    hm.actors,
    hm.movie_type,
    STRING_AGG(DISTINCT mk.keyword, ', ') AS keywords,
    COUNT(*) OVER (PARTITION BY hm.production_year) AS movies_per_year,
    COALESCE(SUM(CASE WHEN mk.keyword ILIKE '%action%' THEN 1 ELSE 0 END), 0) AS action_movie_count
FROM 
    HighlightedMovies hm
LEFT JOIN 
    MovieKeywords mk ON hm.title = mk.title
GROUP BY 
    hm.title, hm.production_year, hm.cast_count, hm.actors, hm.movie_type
ORDER BY 
    hm.production_year DESC, 
    hm.cast_count DESC;

### Explanation:
1. **CTEs (Common Table Expressions)**:
   - `RankedMovies`: Computes a ranking of movies based on the number of distinct cast members, grouping by the year.
   - `HighlightedMovies`: Filters the top 5 movies for each production year, categorizing them as 'Popular' or 'Less Known'.
   - `MovieKeywords`: Gathers keywords associated with the movies.

2. **Main Query**:
   - Joins the highlighted movies with their keywords.
   - Counts the total number of movies per year.
   - Uses a `COALESCE` along with a `SUM` to count how many of those movies have the keyword 'action' in a case-insensitive manner.

3. **Window Functions**:
   - Utilizes window functions to rank movies and count the number of movies per year.

4. **Outer Joins & Aggregate Functions**:
   - The outer join with `MovieKeywords` ensures that even if a movie does not have keywords, it is still included in the result.

5. **Complicated Predicates and NULL Logic**:
   - The use of `FILTER` with `STRING_AGG` and combined conditions using `COALESCE` illustrates handling NULL values in aggregate calculations.

6. **String Expressions and Filters**:
   - Using `ILIKE` for case-insensitive keyword matching, and formatting the actors’ names into a concatenated string.

This SQL query is structured for performance benchmarking by using aggregates and complex joins while providing insightful movie data from the given schema.
