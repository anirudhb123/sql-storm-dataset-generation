WITH RankedMovies AS (
    SELECT 
        mt.title,
        mt.production_year,
        mci.company_id,
        COUNT(DISTINCT ci.person_id) AS total_cast_members,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        aka_title mt
    LEFT JOIN 
        complete_cast cc ON mt.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    LEFT JOIN 
        movie_companies mci ON mt.id = mci.movie_id
    GROUP BY 
        mt.id, mt.title, mt.production_year, mci.company_id
),
CompanyNames AS (
    SELECT 
        cn.id AS company_id,
        cn.name AS company_name,
        ct.kind AS company_type
    FROM 
        company_name cn
    INNER JOIN 
        company_type ct ON cn.id = ct.id
),

FilteredMovies AS (
    SELECT 
        rm.*,
        cn.company_name,
        cn.company_type
    FROM 
        RankedMovies rm
    LEFT JOIN 
        CompanyNames cn ON rm.company_id = cn.company_id
    WHERE 
        rm.total_cast_members > 5 AND 
        (rm.production_year BETWEEN 2000 AND 2023 OR cn.company_type IS NULL)
)

SELECT 
    fm.title,
    fm.production_year,
    COALESCE(fm.company_name, 'Independent') AS production_company,
    fm.total_cast_members,
    SUBSTRING(fm.title FROM '^[a-zA-Z]+') AS title_substring,
    CASE 
        WHEN fm.total_cast_members IS NULL THEN 'Unknown'
        ELSE 'Known'
    END AS cast_status
FROM 
    FilteredMovies fm
WHERE 
    fm.production_company IS NOT NULL
ORDER BY 
    fm.production_year DESC, 
    fm.total_cast_members DESC
FETCH FIRST 10 ROWS ONLY;

### Explanation:
1. **CTEs Used**:
   - `RankedMovies`: It gathers information on movies and their total cast members, ranks them within their production year based on cast size.
   - `CompanyNames`: It pulls company names and their types linked with the company ID.
   - `FilteredMovies`: It filters the movies from `RankedMovies` based on cast size and production year, while also left joining company information.

2. **SELECT Statement**: 
   - Retrieves fields like the movie title, production year, production company (with a fallback), and total cast members.
   - Uses a substring function to extract the initial alphabet of the title.
   - Incorporates a CASE statement to signify whether the cast membership status is known or not.

3. **Conditions and Logic**: 
   - The movie filter considers only those with more than 5 cast members and incorporates NULL checks in the JOIN conditions.
   - The final SELECT statement orders the results by year and total cast members while limiting the result to the top ten records.

This query effectively showcases various SQL features and edge cases, such as `LEFT JOINs` with NULL management, aggregation, window functions, and string manipulation in a complex dataset scenario.
