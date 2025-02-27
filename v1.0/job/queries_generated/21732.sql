WITH RankedMovies AS (
    SELECT 
        at.id AS title_id,
        at.title,
        at.production_year,
        RANK() OVER (PARTITION BY at.production_year ORDER BY at.production_year DESC) AS year_rank
    FROM 
        aka_title at
    WHERE 
        at.production_year IS NOT NULL
),
CastDetails AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
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
        string_agg(DISTINCT cn.name, ', ') AS companies,
        COUNT(DISTINCT mc.company_id) AS total_companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
MovieInfoAggregated AS (
    SELECT 
        at.id AS movie_id,
        at.title,
        COALESCE(rd.total_cast, 0) AS total_cast,
        COALESCE(ci.companies, 'No Companies') AS companies,
        COALESCE(ci.total_companies, 0) AS total_companies,
        ROW_NUMBER() OVER (ORDER BY at.production_year DESC) AS overall_rank
    FROM 
        aka_title at
    LEFT JOIN 
        CastDetails rd ON at.id = rd.movie_id
    LEFT JOIN 
        CompanyInfo ci ON at.id = ci.movie_id
)
SELECT 
    mia.movie_id,
    mia.title,
    mia.total_cast,
    mia.companies,
    mia.total_companies,
    mia.overall_rank,
    CASE 
        WHEN mia.total_cast > 5 THEN 'Large Cast'
        WHEN mia.total_cast BETWEEN 3 AND 5 THEN 'Medium Cast'
        ELSE 'Small Cast'
    END AS cast_size_category,
    EXISTS (
        SELECT 1 
        FROM movie_info mi 
        WHERE mi.movie_id = mia.movie_id 
          AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Box Office')
          AND mi.info IS NOT NULL
    ) AS has_box_office_info
FROM 
    MovieInfoAggregated mia
WHERE 
    mia.total_companies > 0
  AND 
    (mia.title ILIKE '%epic%' OR mia.title ILIKE '%legend%')
  AND 
    mia.overall_rank <= 100
ORDER BY 
    mia.production_year DESC, 
    mia.total_cast DESC
LIMIT 50;

This query captures a variety of SQL constructs, including:
- Common Table Expressions (CTEs) to break down complex logic into digestible parts.
- Window functions (e.g., RANK and ROW_NUMBER) to assign ranks and order the results.
- Outer joins to ensure inclusive results from related tables.
- Correlated subqueries to check conditions in related contexts.
- Use of string aggregation for concatenating names and companies.
- Predicate logic for various checks, including NULL handling and string pattern matching.
- A `CASE` statement for conditional labels based on cast size.
