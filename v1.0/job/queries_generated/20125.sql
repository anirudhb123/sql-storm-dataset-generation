WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, t.title) AS rn
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords_list
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
CastInfoAgg AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        MAX(ci.nr_order) AS max_order,
        STRING_AGG(DISTINCT a.name, ', ') FILTER (WHERE a.name IS NOT NULL) AS cast_names
    FROM 
        cast_info ci
    LEFT JOIN 
        aka_name a ON ci.person_id = a.person_id
    GROUP BY 
        ci.movie_id
),
MovieCompanies AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(cn.name, ', ') AS company_names,
        COUNT(DISTINCT mc.company_type_id) AS company_type_count,
        COUNT(DISTINCT mc.company_id) AS total_companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    COALESCE(k.keywords_list, 'No Keywords') AS keywords,
    COALESCE(c.total_cast, 0) AS total_cast_members,
    COALESCE(c.cast_names, 'No Cast') AS cast_names,
    COALESCE(m.company_names, 'No Companies') AS companies_involved,
    COALESCE(m.company_type_count, 0) AS types_of_companies
FROM 
    RankedMovies rm
LEFT JOIN 
    MovieKeywords k ON rm.title_id = k.movie_id
LEFT JOIN 
    CastInfoAgg c ON rm.title_id = c.movie_id
LEFT JOIN 
    MovieCompanies m ON rm.title_id = m.movie_id
WHERE 
    rm.production_year >= 2000 
    AND (k.keywords_list IS NOT NULL OR c.total_cast > 5)
ORDER BY 
    rm.production_year DESC, 
    rm.title;

### Explanation of Constructs Used:
1. **CTEs**: Four Common Table Expressions (CTEs) aggregate movie information. 
   - `RankedMovies`: Ranks movies by production year.
   - `MovieKeywords`: Aggregates keywords for movies.
   - `CastInfoAgg`: Aggregates cast information including count and names.
   - `MovieCompanies`: Aggregates companies associated with movies.

2. **Window Functions**: Used in the first CTE to rank movies within their production year.

3. **Aggregating with STRING_AGG**: Collects names and keywords into a comma-separated string.

4. **LEFT JOINs**: Ensures that even movies without keywords or cast info are included in the output.

5. **COALESCE**: Handles NULL values gracefully by providing default messages.

6. **Complex Predicates**: The `WHERE` clause employs conditions combining NULL checks and aggregate thresholds.

7. **Order By**: Ordering results primarily by production year and secondarily by title for an organized output. 

8. **Filtering**: Filters results to include only those movies from the year 2000 and later, and where there are keywords or a significant cast. 

This query represents a complex union of various SQL constructs, demonstrating interesting logic and deliberately nuanced behavior regarding NULLs, aggregation, and filtering.
