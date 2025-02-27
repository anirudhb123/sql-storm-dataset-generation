WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COUNT(DISTINCT ci.person_id) OVER (PARTITION BY mt.id) AS cast_count,
        AVG(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) OVER (PARTITION BY mt.id) * 100 AS completeness_percentage
    FROM 
        aka_title mt
    LEFT JOIN 
        cast_info ci ON mt.id = ci.movie_id
    WHERE 
        mt.production_year BETWEEN 2000 AND 2023
),
CompanyMovies AS (
    SELECT 
        mc.movie_id,
        string_agg(DISTINCT cn.name, ', ') AS company_names,
        string_agg(DISTINCT ct.kind, ', ') AS company_types
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
),
FilteredRankedMovies AS (
    SELECT 
        rm.*,
        COALESCE(cm.company_names, 'Unknown') AS company_names,
        COALESCE(cm.company_types, 'N/A') AS company_types
    FROM 
        RankedMovies rm
    LEFT JOIN 
        CompanyMovies cm ON rm.movie_id = cm.movie_id
),
FinalOutput AS (
    SELECT 
        *,
        CASE 
            WHEN completeness_percentage >= 80 THEN 'High'
            WHEN completeness_percentage >= 50 THEN 'Medium'
            ELSE 'Low'
        END AS completeness_level
    FROM 
        FilteredRankedMovies
    WHERE 
        cast_count > 2
)
SELECT 
    f.movie_id,
    f.title,
    f.production_year,
    f.cast_count,
    f.completeness_percentage,
    f.company_names,
    f.company_types,
    f.completeness_level
FROM 
    FinalOutput f
ORDER BY 
    f.production_year DESC, f.cast_count DESC
LIMIT 100;
