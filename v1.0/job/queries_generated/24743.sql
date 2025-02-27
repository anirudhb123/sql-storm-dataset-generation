WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(c.person_id) DESC) AS year_rank
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    GROUP BY 
        a.id, a.title, a.production_year
),
TopMovies AS (
    SELECT 
        title, 
        production_year
    FROM 
        RankedMovies
    WHERE 
        year_rank <= 5
),
MovieKeywords AS (
    SELECT 
        m.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword m
    JOIN 
        keyword k ON m.keyword_id = k.id
    GROUP BY 
        m.movie_id
),
MovieCompanies AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, '; ') AS companies
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
    COALESCE(mcs.companies, 'No Companies') AS companies
FROM 
    TopMovies tm
LEFT JOIN 
    MovieKeywords mk ON tm.production_year = (SELECT production_year FROM aka_title WHERE id = tm.id)
LEFT JOIN 
    MovieCompanies mcs ON mcs.movie_id = (SELECT id FROM aka_title WHERE title = tm.title AND production_year = tm.production_year)
ORDER BY 
    tm.production_year DESC, 
    tm.title;

### Explanation:
1. **CTEs**:
   - `RankedMovies`: Calculates the number of cast members for each movie and ranks them by year.
   - `TopMovies`: Filters the top 5 movies by cast count for each year.
   - `MovieKeywords`: Aggregates keywords for each movie.
   - `MovieCompanies`: Aggregates companies associated with each movie.

2. **Outer Joins**: 
   - Used to accommodate movies that may not have associated keywords or companies.

3. **string_agg() Function**: 
   - Creates a comma-separated list of keywords and companies.

4. **Correlated Subqueries**: 
   - Utilized to fetch the production year and ID of the movies within the CTEs.

5. **NULL Logic**: 
   - `COALESCE` is used to handle cases where no keywords or companies exist, returning a more human-readable string.

This query provides rich information about the top movies in terms of cast, along with their associated keywords and production companies while gracefully handling potential NULL values.
