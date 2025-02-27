WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS year_rank
    FROM 
        aka_title t
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
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
    WHERE 
        c.country_code IS NOT NULL
),
CastDetails AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS actor_names
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        ci.movie_id
),
SubQueryMovies AS (
    SELECT 
        mt.movie_id,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        aka_title mt ON mk.movie_id = mt.id
    GROUP BY 
        mt.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    COALESCE(rm.production_year, 'Unknown Year') AS production_year,
    COALESCE(cd.cast_count, 0) AS total_cast,
    COALESCE(ci.company_name, 'Independent') AS production_company,
    COALESCE(ci.company_type, 'N/A') AS company_type,
    COALESCE(sm.keyword_count, 0) AS total_keywords
FROM 
    RankedMovies rm
LEFT JOIN 
    CastDetails cd ON rm.movie_id = cd.movie_id
LEFT JOIN 
    CompanyInfo ci ON rm.movie_id = ci.movie_id
LEFT JOIN 
    SubQueryMovies sm ON rm.movie_id = sm.movie_id
WHERE 
    rm.year_rank <= 10
ORDER BY 
    rm.production_year DESC NULLS LAST,
    total_cast DESC,
    rm.title ASC;

### Explanation:
1. **Common Table Expressions (CTEs)**: 
   - `RankedMovies`: Ranks movies by title within each production year.
   - `CompanyInfo`: Retrieves production companies, ensuring country codes are not NULL.
   - `CastDetails`: Aggregates cast counts and names for each movie.
   - `SubQueryMovies`: Counts keywords linked to each movie.
  
2. **Joins**:
   - Left joins are used to ensure that if a movie lacks cast, company info, or keywords, it still appears in the results. 

3. **COALESCE**: Handles possible NULL values by providing fallbacks for production year, cast count, company name, company type, and keyword count.

4. **Predicates**:
   - Filtering to include only the top 10 movies per year using a ranked window function.

5. **Order By**: Orders the final results first by production year (descending), then by total cast (descending), and finally by title (ascending) to provide an easily readable output.

This complex query benchmarks performance through layered complexity and a variety of SQL constructs, making it useful for testing various database optimizations.
