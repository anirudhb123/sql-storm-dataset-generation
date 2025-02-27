WITH RankedMovies AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        a.kind_id,
        COUNT(DISTINCT c.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    GROUP BY 
        a.id
),
MovieKeywords AS (
    SELECT 
        m.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords_list
    FROM 
        movie_keyword m
    JOIN 
        keyword k ON m.keyword_id = k.id
    GROUP BY 
        m.movie_id
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
TopMovies AS (
    SELECT 
        rm.movie_title,
        rm.production_year,
        mk.keywords_list,
        ci.company_name,
        ci.company_type
    FROM 
        RankedMovies rm
    LEFT JOIN 
        MovieKeywords mk ON rm.movie_title = mk.movie_id
    LEFT JOIN 
        CompanyInfo ci ON rm.movie_title = ci.movie_id
    WHERE 
        rm.rank <= 5
)
SELECT 
    COALESCE(tm.movie_title, 'Unknown Title') AS movie_title,
    tm.production_year,
    COALESCE(tm.keywords_list, 'No keywords') AS keywords,
    COALESCE(tm.company_name, 'No Company') AS production_company,
    COALESCE(tm.company_type, 'Unknown Type') AS type_of_company
FROM 
    TopMovies tm
FULL OUTER JOIN 
    aka_name an ON tm.movie_title = an.name 
WHERE 
    (tm.production_year IS NOT NULL OR an.name IS NOT NULL)
ORDER BY 
    tm.production_year DESC, 
    tm.movie_title ASC;

This SQL query performs the following:

1. **CTEs**:
   - `RankedMovies`: Ranks movies by the number of distinct actors for each production year.
   - `MovieKeywords`: Aggregates keywords for each movie into a comma-separated string.
   - `CompanyInfo`: Joins movie companies with their names and types.

2. **Main Query**:
   - Combines results from the previously defined CTEs to fetch the top 5 movies from the `RankedMovies` based on actor count. 

3. **FULL OUTER JOIN**: 
   - Joins with the `aka_name` table to include any additional movie names, showing a record even if one side is NULL.

4. **NULL Logic**:
   - Uses `COALESCE` to handle NULLs and provide meaningful default values (e.g., 'Unknown Title', 'No keywords').

5. **Ordering and Filtering**: 
   - Results are ordered by production year and movie title while ensuring that at least one of the join components has a non-NULL value.

This query showcases various SQL constructs including CTEs, outer joins, aggregation functions, and string manipulation techniques.
