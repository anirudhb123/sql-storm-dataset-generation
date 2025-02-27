WITH RecursiveTitleCTE AS (
    SELECT 
        title.id AS title_id,
        title.title,
        title.production_year,
        COALESCE(NULLIF(AKA.name, ''), 'Unknown') AS aka_name,
        ROW_NUMBER() OVER (PARTITION BY title.production_year ORDER BY title.id) AS rn
    FROM 
        aka_title AKA 
    JOIN 
        title ON AKA.movie_id = title.id
    WHERE 
        title.production_year IS NOT NULL
),
CastStats AS (
    SELECT 
        C.movie_id,
        COUNT(DISTINCT C.person_id) AS total_cast,
        COUNT(CASE WHEN R.role IS NOT NULL THEN 1 END) AS credited_cast,
        COUNT(CASE WHEN R.role IS NULL THEN 1 END) AS uncredited_cast
    FROM 
        cast_info C
    LEFT JOIN 
        role_type R ON C.role_id = R.id
    GROUP BY 
        C.movie_id
),
MovieKeywordStats AS (
    SELECT 
        MK.movie_id,
        STRING_AGG(K.keyword, ', ') AS keywords
    FROM 
        movie_keyword MK
    JOIN 
        keyword K ON MK.keyword_id = K.id
    GROUP BY 
        MK.movie_id
),
TitleWithStats AS (
    SELECT 
        RTC.title_id,
        RTC.title,
        RTC.production_year,
        CS.total_cast,
        CS.credited_cast,
        CS.uncredited_cast,
        MKS.keywords
    FROM 
        RecursiveTitleCTE RTC
    LEFT JOIN 
        CastStats CS ON RTC.title_id = CS.movie_id
    LEFT JOIN 
        MovieKeywordStats MKS ON RTC.title_id = MKS.movie_id
)
SELECT 
    title_id,
    title,
    production_year,
    total_cast,
    credited_cast,
    uncredited_cast,
    COALESCE(keywords, 'No Keywords') AS keywords,
    CASE 
        WHEN total_cast > 50 THEN 'Large Cast'
        WHEN total_cast BETWEEN 20 AND 50 THEN 'Medium Cast'
        WHEN total_cast < 20 THEN 'Small Cast'
        ELSE 'Unknown Cast Size'
    END AS cast_size_category,
    CASE 
        WHEN production_year < 2000 THEN 'Classic'
        WHEN production_year BETWEEN 2000 AND 2020 THEN 'Modern'
        ELSE 'Recent'
    END AS era
FROM 
    TitleWithStats
WHERE 
    CAST(production_year AS VARCHAR) LIKE '2%'  -- Only taking movies from the 21st century
ORDER BY 
    production_year DESC, 
    total_cast DESC
LIMIT 100;

### Explanation:
- **Common Table Expressions (CTEs):** The query uses CTEs to construct intermediate tables for the main query. This includes a recursive CTE for titles, calculating statistics about cast members, and aggregating movie keywords.
- **Row Number:** The `ROW_NUMBER()` window function assigns a sequential number to each title within its production year.
- **Aggregations:** Counts of total, credited, and uncredited cast members are computed using aggregate functions.
- **String Aggregation:** `STRING_AGG` aggregates keywords into a single string for each movie.
- **NULL Handling:** The use of `COALESCE` and `NULLIF` to manage NULL values dynamically.
- **Conditional Logic:** Cases to categorize movies into "cast size" and "era" based on production year.
- **String Operations:** The use of `CAST` to filter only those movies produced in the 21st century.
- **Limiting Results:** The final result set is limited to 100 entries, sorted by production year and total cast in descending order. This query exemplifies numerous facets of SQL for performance benchmarking as requested.
