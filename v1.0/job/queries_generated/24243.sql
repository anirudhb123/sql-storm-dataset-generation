WITH RecursiveYearStats AS (
    SELECT 
        CT.production_year,
        COUNT(DISTINCT CI.person_id) AS total_cast,
        COUNT(DISTINCT M.id) AS total_movies,
        AVG(CASE WHEN CI.nr_order IS NOT NULL THEN CI.nr_order ELSE 0 END) AS avg_cast_order
    FROM 
        aka_title AT
    JOIN 
        cast_info CI ON AT.movie_id = CI.movie_id
    JOIN 
        title T ON AT.id = T.id
    JOIN 
        movie_companies MC ON M.id = MC.movie_id
    JOIN 
        (SELECT DISTINCT production_year FROM aka_title) CT 
    ON 
        T.production_year = CT.production_year
    GROUP BY 
        CT.production_year
),
RankedMovies AS (
    SELECT 
        T.title,
        T.production_year,
        ROW_NUMBER() OVER (PARTITION BY T.production_year ORDER BY COUNT(MC.company_id) DESC) AS rank_by_company_count
    FROM 
        title T
    LEFT JOIN 
        movie_companies MC ON T.id = MC.movie_id
    GROUP BY 
        T.title, T.production_year
),
TopMovies AS (
    SELECT 
        R.title,
        R.production_year,
        RS.total_cast,
        R.rank_by_company_count
    FROM 
        RankedMovies R
    JOIN 
        RecursiveYearStats RS ON R.production_year = RS.production_year
    WHERE 
        R.rank_by_company_count <= 5
),
MovieKeywords AS (
    SELECT 
        MT.movie_id,
        STRING_AGG(K.keyword, ', ') AS keywords
    FROM 
        movie_keyword MT
    JOIN 
        keyword K ON MT.keyword_id = K.id
    GROUP BY 
        MT.movie_id
),
FinalOutput AS (
    SELECT 
        TM.title,
        TM.production_year,
        TM.total_cast,
        MK.keywords,
        COALESCE(NULLIF(TM.total_movies, 0), "No movies listed") AS movie_count
    FROM 
        TopMovies TM
    LEFT JOIN 
        MovieKeywords MK ON TM.movie_id = MK.movie_id
)
SELECT 
    FO.*,
    CASE 
        WHEN FO.total_cast > 10 THEN 'Large Cast'
        WHEN FO.total_cast BETWEEN 5 AND 10 THEN 'Medium Cast'
        ELSE 'Small Cast'
    END AS cast_size_category
FROM 
    FinalOutput FO
WHERE 
    FO.movie_count IS NOT NULL OR FO.keywords IS NOT NULL
ORDER BY 
    FO.production_year DESC, FO.title ASC;

### Explanation of the SQL Query:
1. **Common Table Expressions (CTEs)**: The query uses multiple CTEs:
   - `RecursiveYearStats` computes aggregate statistics by `production_year`.
   - `RankedMovies` ranks titles based on the number of companies associated with each movie.
   - `TopMovies` selects the top-ranked movies, limiting results to the top 5 per year and including total cast.
   - `MovieKeywords` aggregates keywords associated with movies.

2. **Joins**: It employs both inner and outer joins to link multiple tables. LEFT JOINs are used to include all records from the main tables while allowing for NULLs from secondary tables.

3. **Window Functions**: The `ROW_NUMBER()` is used to assign a rank based on company count.

4. **Aggregations and String Functions**: The query showcases `COUNT(DISTINCT ...)`, `AVG(...)`, and `STRING_AGG(...)` for manipulating data sets.

5. **Conditional Logic**: Utilizes `COALESCE` and `NULLIF` to handle NULL values logically and produce refined outputs.

6. **Complicated Predicates and Calculations**: There are several expressions, especially in the average calculations and case constructs, which evaluate different conditions of the dataset.

7. **Ordering**: Finally, results are ordered by `production_year` and then by `title`.

This complex structure is designed to handle multiple aspects of movie casting and production statistics with nuanced categorizations and options for handling missing or null data, reflecting intricate database relationships and SQL capabilities.
