WITH RankedMovies AS (
    SELECT 
        T.id AS movie_id,
        T.title,
        T.production_year,
        ROW_NUMBER() OVER (PARTITION BY T.production_year ORDER BY T.title) AS rn,
        COUNT(*) OVER (PARTITION BY T.production_year) AS total_per_year
    FROM
        aka_title T
    WHERE
        T.production_year IS NOT NULL
),
CastStatistics AS (
    SELECT 
        C.movie_id,
        COUNT(DISTINCT C.person_id) AS distinct_cast_count,
        AVG(C.nr_order) AS avg_order,
        MAX(C.nr_order) AS max_order
    FROM
        cast_info C
    GROUP BY 
        C.movie_id
),
CompanyStats AS (
    SELECT 
        M.movie_id,
        C.name AS company_name,
        COUNT(*) AS company_count,
        STRING_AGG(DISTINCT CT.kind, ', ') AS company_types
    FROM
        movie_companies M
    JOIN
        company_name C ON M.company_id = C.id
    JOIN
        company_type CT ON M.company_type_id = CT.id
    GROUP BY 
        M.movie_id, C.name
),
FinalResults AS (
    SELECT 
        R.movie_id,
        R.title,
        R.production_year,
        R.total_per_year,
        COALESCE(CS.distinct_cast_count, 0) AS distinct_cast_count,
        COALESCE(CS.avg_order, 0) AS avg_order,
        COALESCE(CS.max_order, 0) AS max_order,
        COALESCE(CO.company_name, 'No Company') AS company_name,
        COALESCE(CO.company_types, 'None') AS company_types
    FROM 
        RankedMovies R
    LEFT JOIN 
        CastStatistics CS ON R.movie_id = CS.movie_id
    LEFT JOIN 
        CompanyStats CO ON R.movie_id = CO.movie_id
    WHERE 
        R.production_year >= 2000
        AND (CS.distinct_cast_count IS NULL OR CS.distinct_cast_count > 3)
)

SELECT 
    F.movie_id,
    F.title,
    F.production_year,
    F.total_per_year,
    F.distinct_cast_count,
    F.avg_order,
    F.max_order,
    TRIM(BOTH ' ' FROM F.company_name) AS clean_company_name,
    UPPER(F.company_types) AS uppercase_company_types,
    CASE 
        WHEN F.production_year % 2 = 0 THEN 'Even Year' 
        ELSE 'Odd Year' 
    END AS year_type,
    CASE 
        WHEN F.distinct_cast_count > 10 THEN 'Ensemble Cast'
        ELSE 'Regular Cast'
    END AS cast_type
FROM 
    FinalResults F
WHERE 
    F.distinct_cast_count < F.total_per_year
ORDER BY 
    F.production_year DESC, F.title ASC
LIMIT 100;
