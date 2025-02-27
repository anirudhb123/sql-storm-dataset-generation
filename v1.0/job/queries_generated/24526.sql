WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.id) AS movie_rank
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL
),
CastDetails AS (
    SELECT 
        ci.movie_id,
        COUNT(ci.role_id) AS role_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS cast_names
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        ci.movie_id
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
FilteredMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        cd.role_count,
        cd.cast_names,
        COALESCE(ci.company_name, 'Independent') AS first_company_name
    FROM 
        RankedMovies rm
    LEFT JOIN 
        CastDetails cd ON rm.movie_id = cd.movie_id
    LEFT JOIN 
        CompanyInfo ci ON rm.movie_id = ci.movie_id AND ci.company_type = 'Distributor'
    WHERE 
        (rm.production_year < 2000 OR cd.role_count > 5) AND
        (cd.cast_names IS NOT NULL OR ci.company_name IS NULL)
)
SELECT 
    fm.title,
    fm.production_year,
    fm.role_count,
    fm.cast_names,
    COUNT(DISTINCT mk.keyword) AS keyword_count
FROM 
    FilteredMovies fm
LEFT JOIN 
    movie_keyword mk ON fm.movie_id = mk.movie_id
WHERE 
    UPPER(fm.first_company_name) NOT LIKE '%DISNEY%'
GROUP BY 
    fm.title, fm.production_year, fm.role_count, fm.cast_names
HAVING 
    COUNT(DISTINCT mk.keyword) > 0
ORDER BY 
    fm.production_year DESC, fm.role_count DESC;

This SQL query is structured as follows:

1. **Common Table Expressions (CTEs)**:
   - `RankedMovies`: Retrieves movies ranked by their production year and assigned a row number for each year.
   - `CastDetails`: Aggregates cast information, counting roles and concatenating cast member names per movie.
   - `CompanyInfo`: Joins movie companies with their names and types.
   - `FilteredMovies`: Filters the movies based on specific criteria regarding the production year and the count of cast roles.

2. **Final Selection**: 
   - The outer query selects titles, production years, role counts, and cast names from `FilteredMovies`, joins it with the `movie_keyword` table to count associated keywords while ensuring certain criteria around the company name.

3. **Complex Predicates and Expressions**: Uses `COALESCE`, `IS NOT NULL`, and conditional comparisons to refine the results.

4. **Unusual Joins**: It uses left joins to account for movies with or without associated cast or companies.

5. **String and Uppercase Expression**: Ensures case-insensitive comparison against a keyword ('DISNEY').

6. **Bizarre SQL Semantics**: Incorporates the logic of comparing counts and filtering based on the characteristics of companies and details from various related entities.

The query is designed for performance benchmarking by measuring how complex joins, aggregates, and filtering perform against a realistic dataset derived from the Join Order Benchmark schema.
