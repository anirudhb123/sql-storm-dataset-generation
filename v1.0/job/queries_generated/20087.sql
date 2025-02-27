WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank,
        COALESCE(SUM(CASE WHEN c.nr_order IS NOT NULL THEN 1 ELSE 0 END), 0) AS total_cast
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    GROUP BY 
        t.id, t.title, t.production_year
), 
TopNMovies AS (
    SELECT 
        * 
    FROM 
        RankedMovies 
    WHERE 
        title_rank <= 5
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
MovieCompanies AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)

SELECT 
    tm.title,
    tm.production_year,
    COALESCE(mk.keywords, 'No Keywords') AS keywords,
    COALESCE(mc.companies, 'No Companies') AS companies,
    CASE 
        WHEN tm.total_cast = 0 THEN 'No Cast'
        ELSE CONCAT(CAST(tm.total_cast AS TEXT), ' Cast Members')
    END AS cast_info
FROM 
    TopNMovies tm
LEFT JOIN 
    MovieKeywords mk ON tm.movie_id = mk.movie_id
LEFT JOIN 
    MovieCompanies mc ON tm.movie_id = mc.movie_id
WHERE 
    tm.production_year >= (SELECT MIN(production_year) FROM aka_title)
      AND tm.production_year <= (SELECT MAX(production_year) FROM aka_title)
ORDER BY 
    tm.production_year DESC, tm.title ASC;

This SQL query does the following:

1. **RankedMovies CTE**: Creates a ranked list of movies per production year, counting associated cast members.
   
2. **TopNMovies CTE**: Selects the top 5 movies for each production year.

3. **MovieKeywords CTE**: Aggregates keywords associated with movies.

4. **MovieCompanies CTE**: Aggregates the names of companies associated with movies.

5. The final SELECT statement combines data from the top movies, keywords, and companies, including handling NULLs with default values and a case for cast member counts. 

6. The filtering criteria ensure that only movies within the range of production years found in the database are selected, and results are ordered by production year and title.

This complex query showcases various SQL constructs such as CTEs, aggregate functions, and conditional logic while demonstrating more obscure semantics like handling NULLs in a descriptive output.
