
WITH RankedMovies AS (
    SELECT 
        mt.title AS movie_title,
        mt.production_year,
        COUNT(cc.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY COUNT(cc.person_id) DESC) AS rank_by_cast
    FROM 
        aka_title mt
    LEFT JOIN 
        complete_cast mc ON mt.id = mc.movie_id
    LEFT JOIN 
        cast_info cc ON mc.subject_id = cc.id
    GROUP BY 
        mt.title, mt.production_year
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ' ORDER BY cn.name) AS company_names,
        COUNT(DISTINCT ct.kind) AS company_types_count
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
),
MoviesWithKeyDetails AS (
    SELECT 
        rt.movie_title,
        rt.production_year,
        cd.company_names,
        cd.company_types_count,
        rt.cast_count,
        CASE
            WHEN rt.cast_count > 5 THEN 'Ensemble Cast'
            WHEN rt.cast_count BETWEEN 3 AND 5 THEN 'Moderate Cast'
            ELSE 'Small Cast'
        END AS cast_size_category
    FROM 
        RankedMovies rt
    LEFT JOIN 
        CompanyDetails cd ON rt.movie_title = (
            SELECT title FROM aka_title WHERE id = cd.movie_id
        )
)
SELECT 
    mwkd.movie_title,
    mwkd.production_year,
    mwkd.company_names,
    mwkd.company_types_count,
    mwkd.cast_size_category,
    COALESCE(NULLIF(mwkd.cast_size_category, 'Small Cast'), 'Not Classified') AS adjusted_cast_category,
    COUNT(*) OVER() AS total_movies
FROM 
    MoviesWithKeyDetails mwkd
WHERE 
    mwkd.production_year >= 2000
    AND mwkd.company_types_count > 1
ORDER BY 
    mwkd.production_year DESC,
    mwkd.cast_count DESC
LIMIT 1000;
