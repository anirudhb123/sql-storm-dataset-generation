WITH RankedMovies AS (
    SELECT 
        a.id AS aka_id,
        a.name AS aka_name,
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY t.production_year DESC) AS rn,
        MAX(CASE WHEN t.production_year IS NOT NULL THEN t.production_year ELSE 0 END) OVER (PARTITION BY a.person_id) AS latest_year
    FROM 
        aka_name a
    JOIN 
        aka_title t ON a.id = t.id
    WHERE 
        a.name IS NOT NULL
),
TopMovies AS (
    SELECT 
        rm.aka_id, 
        rm.aka_name, 
        rm.title, 
        rm.production_year 
    FROM 
        RankedMovies rm 
    WHERE 
        rm.rn <= 5 
        AND rm.production_year > (SELECT AVG(production_year) FROM aka_title)
),
MovieDetails AS (
    SELECT 
        t.title,
        c.kind AS company_type,
        COUNT(DISTINCT mc.company_id) AS company_count,
        STRING_AGG(DISTINCT mc.note, ', ') AS company_notes,
        COUNT(DISTINCT k.keyword) AS keyword_count
    FROM 
        TopMovies tm
    LEFT JOIN 
        complete_cast cc ON cc.movie_id = tm.title_id
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = cc.movie_id
    LEFT JOIN 
        company_type c ON c.id = mc.company_type_id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = cc.movie_id
    LEFT JOIN 
        keyword k ON k.id = mk.keyword_id
    GROUP BY 
        t.title, c.kind
)
SELECT 
    md.title,
    md.company_type,
    md.company_count,
    md.company_notes,
    COALESCE(md.keyword_count, 0) AS keyword_count,
    CASE 
        WHEN md.company_count > 0 THEN 'Produced by companies'
        ELSE 'Independent'
    END AS production_type,
    CASE 
        WHEN tm.production_year = md.production_year THEN 'Latest'
        ELSE 'Older'
    END AS movie_age_classification
FROM 
    MovieDetails md
JOIN 
    TopMovies tm ON md.title = tm.title
WHERE 
    tm.production_year < (SELECT MIN(production_year) FROM aka_title WHERE production_year IS NOT NULL)
  AND 
    (md.company_count IS NOT NULL OR md.company_notes IS NOT NULL)
ORDER BY 
    md.company_count DESC, 
    md.keyword_count DESC;

### Explanation:
1. **CTEs**: 
   - `RankedMovies` ranks movies per person based on production year.
   - `TopMovies` filters to the top 5 recent movies that exceed the average production year.
   - `MovieDetails` collects various statistics for these top movies, including company counts and keyword counts.

2. **Outer Join**: The use of left joins in `MovieDetails` allows retaining movies even if they lack certain associations (like company details).

3. **Window Functions**: `ROW_NUMBER()` in `RankedMovies` assigns ranks based on the `production_year`.

4. **String Aggregation**: `STRING_AGG` is used to consolidate company notes.

5. **NULL Logic**: `COALESCE` converts NULL keyword counts to 0.

6. **Complex Conditions**: The final selection includes a classification of the production type and age of the movie based on the available data.

7. **Bizarre SQL Semantics**: Multiple conditions to filter and categorize entries based on subquery results and aggregate functions showcase potential edge cases in logic conditions while still being valid SQL. 

This query serves as a performance benchmark for complex scenarios in SQL querying.
