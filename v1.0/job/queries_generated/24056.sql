WITH RankedMovies AS (
    SELECT
        T.id AS title_id,
        T.title,
        T.production_year,
        ROW_NUMBER() OVER (PARTITION BY T.production_year ORDER BY T.id) AS rank_per_year,
        COUNT(DISTINCT CAST.person_id) OVER (PARTITION BY T.id) AS cast_count
    FROM title T
    LEFT JOIN cast_info CAST ON T.id = CAST.movie_id
    WHERE T.production_year IS NOT NULL
),
TitleWithKeywords AS (
    SELECT
        TM.title_id,
        TM.title,
        TM.production_year,
        COALESCE(K.keyword, 'No Keyword') AS keyword
    FROM RankedMovies TM
    LEFT JOIN movie_keyword MK ON TM.title_id = MK.movie_id
    LEFT JOIN keyword K ON MK.keyword_id = K.id
),
CompanyMovieInfo AS (
    SELECT
        M.movie_id,
        C.name AS company_name,
        CT.kind AS company_type,
        M.info AS movie_info
    FROM movie_companies M
    JOIN company_name C ON M.company_id = C.id
    JOIN company_type CT ON M.company_type_id = CT.id
),
FilteredMovies AS (
    SELECT
        TWK.title,
        TWK.production_year,
        CMI.company_name,
        CMI.company_type,
        TWK.keyword,
        CM.cast_count
    FROM TitleWithKeywords TWK
    LEFT JOIN CompanyMovieInfo CMI ON TWK.title_id = CMI.movie_id
    WHERE TWK.rank_per_year <= 3
      AND TWK.keyword <> 'No Keyword'
      AND CMI.company_type IS NOT NULL
)
SELECT
    FM.title,
    FM.production_year,
    FM.company_name,
    FM.company_type,
    FM.keyword,
    FM.cast_count,
    CASE
        WHEN FM.production_year < 2000 THEN 'Classic'
        WHEN FM.production_year BETWEEN 2000 AND 2010 THEN 'Modern Classic'
        ELSE 'Contemporary'
    END AS era,
    COALESCE(NULLIF(FM.company_type, 'Distributor'), 'Other') AS adjusted_company_type,
    CONCAT('Title: ', FM.title, ' | Year: ', FM.production_year) AS title_info
FROM FilteredMovies FM
ORDER BY FM.production_year DESC, FM.cast_count DESC
LIMIT 50;

### Explanation:
1. **Common Table Expressions (CTEs)**:
   - `RankedMovies`: Ranks movies within their production year and counts distinct cast members.
   - `TitleWithKeywords`: Joins ranked movies with keywords to include keyword information.
   - `CompanyMovieInfo`: Joins movie companies with their names and types.
   - `FilteredMovies`: Combines the above CTEs while filtering for top-ranked movies and non-null company types.

2. **Complicated filtering logic**:
   - Uses `NULLIF()` and `COALESCE()` to adjust the company type for specific entries.
   - Separates movies into different eras based on their production year using a `CASE` statement.

3. **String Expressions**: 
   - Combines strings to create informative output in `title_info`.

4. **Outer Joins**: 
   - Various outer joins are used to ensure that all relevant data is included, even if some relationships do not exist.

5. **Window Functions**:
   - Utilizes `ROW_NUMBER()` and `COUNT()` for analytical purposes, showing how these movies compare against each other.

6. **Correlated Subqueries**: 
   - Implicitly through the use of `COUNT(DISTINCT ... ) OVER (...)` which creates a dynamic count per movie.

7. **Order and Limit**:
   - Provides an ordered and limited output to benchmark performance effectively. 

This elaborate SQL query covers a comprehensive suite of SQL features and intricacies that could serve well in performance benchmarking scenarios.
