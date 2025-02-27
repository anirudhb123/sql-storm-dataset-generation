WITH RankedMovies AS (
    SELECT 
        tt.id AS title_id,
        tt.title,
        tt.production_year,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        ROW_NUMBER() OVER (PARTITION BY tt.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS year_rank
    FROM 
        aka_title tt
    LEFT JOIN 
        cast_info ci ON tt.id = ci.movie_id
    WHERE 
        tt.production_year IS NOT NULL
    GROUP BY 
        tt.id
),
HighCastMovies AS (
    SELECT 
        rm.title_id,
        rm.title,
        rm.production_year
    FROM 
        RankedMovies rm
    WHERE 
        rm.year_rank <= 10
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
CompanyMovieCounts AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mci.company_id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        movie_info mi ON mc.movie_id = mi.movie_id
    JOIN 
        movie_info_idx mii ON mii.movie_id = mi.movie_id
    LEFT JOIN 
        movie_info mi2 ON mc.movie_id = mi2.movie_id AND mi2.info_type_id = mii.info_type_id
    WHERE 
        mii.info LIKE '%international%' OR mii.info IS NULL
    GROUP BY 
        mc.movie_id
)

SELECT 
    hm.title,
    hm.production_year,
    COALESCE(mk.keywords, 'No Keywords') AS keywords,
    COALESCE(cc.company_count, 0) AS company_count
FROM 
    HighCastMovies hm
LEFT JOIN 
    MovieKeywords mk ON hm.title_id = mk.movie_id
LEFT JOIN 
    CompanyMovieCounts cc ON hm.title_id = cc.movie_id
WHERE 
    (hm.production_year <= 2000 AND cc.company_count > 2)
    OR (hm.production_year > 2000 AND mk.keywords IS NOT NULL)
ORDER BY 
    hm.production_year DESC, 
    COALESCE(cc.company_count, 0) DESC;

This SQL query is designed for performance benchmarking and showcases various constructs and features of SQL:

- **Common Table Expressions (CTEs)**: Utilized to structure the query making it more readable, including `RankedMovies`, `HighCastMovies`, `MovieKeywords`, and `CompanyMovieCounts`.
- **Window Functions**: Leveraged `ROW_NUMBER()` to rank movies by the number of distinct cast members per production year.
- **Set Operators**: Incorporated COUNT and STRING_AGG for aggregating information from various movie-related tables.
- **Outer Joins**: Used LEFT JOINs to ensure movies are still returned even if there's no associated keyword or company data.
- **Complicated Predicates and Expressions**: Includes complex WHERE clauses that apply conditions based on both year and categories to filter results.
- **COALESCE Function**: Handles NULL logic to provide default values for keywords and company count.
- **String Expressions**: Used `STRING_AGG` to concatenate keywords associated with movies.

This complexity allows the query to serve as a rigorous benchmark for performance evaluation on different SQL engines while assessing their handling of both large data and intricate joins and aggregations.
