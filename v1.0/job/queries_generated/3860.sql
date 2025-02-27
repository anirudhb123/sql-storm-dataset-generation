WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.id) AS rank,
        COUNT(DISTINCT ci.person_id) OVER (PARTITION BY mt.id) AS cast_count
    FROM 
        aka_title mt
    JOIN 
        complete_cast cc ON mt.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    WHERE 
        mt.production_year IS NOT NULL
),
TopCastMovies AS (
    SELECT 
        rm.movie_id, 
        rm.title, 
        rm.production_year, 
        rm.cast_count
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank <= 5
),
CompanyStats AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT cn.id) AS company_count,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
MovieStatistics AS (
    SELECT 
        t.movie_id, 
        t.title, 
        t.production_year, 
        COALESCE(cs.company_count, 0) AS company_count,
        COALESCE(cs.companies, 'None') AS companies,
        t.cast_count
    FROM 
        TopCastMovies t
    LEFT JOIN 
        CompanyStats cs ON t.movie_id = cs.movie_id
)
SELECT 
    ms.movie_id,
    ms.title,
    ms.production_year,
    ms.company_count,
    ms.companies,
    ms.cast_count,
    CASE WHEN ms.cast_count > 10 THEN 'Ensemble Cast' ELSE 'Small Cast' END AS cast_size_category
FROM 
    MovieStatistics ms
WHERE 
    ms.production_year BETWEEN 2000 AND 2023
ORDER BY 
    ms.production_year DESC, 
    ms.cast_count DESC
LIMIT 20;

