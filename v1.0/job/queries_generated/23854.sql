WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id, 
        t.title AS movie_title, 
        t.production_year, 
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank
    FROM 
        aka_title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON ci.movie_id = t.id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT
        movie_id,
        movie_title,
        production_year
    FROM
        RankedMovies
    WHERE
        rank <= 5
),
MovieGenres AS (
    SELECT 
        mt.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        aka_title mt ON mk.movie_id = mt.id
    GROUP BY 
        mt.movie_id
),
MovieCompanies AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names 
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    WHERE 
        mc.company_type_id IN (SELECT id FROM company_type WHERE kind ILIKE '%Production%')
    GROUP BY 
        mc.movie_id
)

SELECT 
    tm.movie_title,
    tm.production_year,
    COALESCE(mg.keywords, 'No Keywords') as keywords,
    COALESCE(mc.company_names, 'No Companies') as production_companies
FROM 
    TopMovies tm
LEFT JOIN 
    MovieGenres mg ON tm.movie_id = mg.movie_id
LEFT JOIN 
    MovieCompanies mc ON tm.movie_id = mc.movie_id
WHERE 
    (tm.production_year IS NOT NULL OR tm.movie_title IS NOT NULL) 
    AND (REGEXP_MATCH(tm.movie_title, '^[A-Za-z].*') OR tm.production_year IS NULL)
ORDER BY 
    tm.production_year DESC, 
    tm.movie_title;

### Explanation of Query Constructs:
1. **Common Table Expressions (CTEs):**
   - `RankedMovies`: Computes a rank based on the number of cast members per movie, partitioned by production year.
   - `TopMovies`: Filters top 5 movies from each production year based on the rank calculated in `RankedMovies`.
   - `MovieGenres`: Aggregates keywords for each movie using `STRING_AGG` to create a comma-separated list of keywords.
   - `MovieCompanies`: Aggregates production company names for each movie.

2. **Outer Joins:**
   - The main query uses `LEFT JOIN` to include movies even if they do not have associated keywords or production companies.

3. **Complicated Predicates/Expressions:**
   - Uses `COALESCE` to provide default values in case of `NULL` results, ensuring that the output is user-friendly.

4. **String Expressions:**
   - `REGEXP_MATCH` checks leading characters of movie titles to filter out non-informative titles.

5. **Window Functions:**
   - `ROW_NUMBER()` provides a ranking within each production year, underpinning the concept of top movies in a specific year.

6. **NULL Logic:**
   - The `WHERE` clause considers `NULL` values to ensure that movies with missing information are not disproportionately filtered out.

This complex SQL query demonstrates advanced SQL features while operating on the `Join Order Benchmark` schema with an effort to handle varying edge cases and unusual SQL semantics strategically.
