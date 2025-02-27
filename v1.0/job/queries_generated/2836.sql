WITH RankedMovies AS (
    SELECT 
        mt.title, 
        mt.production_year,
        ARRAY_AGG(DISTINCT cn.name) AS companies,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY COUNT(DISTINCT ca.person_id) DESC) AS rn
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_companies mc ON mt.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        complete_cast cc ON mt.id = cc.movie_id
    LEFT JOIN 
        cast_info ca ON cc.subject_id = ca.id
    WHERE 
        mt.production_year IS NOT NULL
    GROUP BY 
        mt.title, mt.production_year
),
FilteredMovies AS (
    SELECT 
        rm.title, 
        rm.production_year, 
        rm.companies
    FROM 
        RankedMovies rm
    WHERE 
        rm.rn <= 5
)
SELECT 
    f.title, 
    f.production_year, 
    COALESCE(f.companies[1], 'No companies') AS first_company,
    JSONB_AGG(DISTINCT JSONB_BUILD_OBJECT('year', f.production_year, 'title', f.title)) AS movie_info
FROM 
    FilteredMovies f
LEFT JOIN 
    movie_info mi ON f.title = mi.info
WHERE 
    f.production_year BETWEEN 2000 AND 2023
GROUP BY 
    f.title, f.production_year
HAVING 
    COUNT(mi.info_type_id) > 0
ORDER BY 
    f.production_year DESC, f.title;
