WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        a.id AS movie_id,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) AS rank_year,
        COUNT(DISTINCT c.person_id) OVER (PARTITION BY a.id) AS cast_count
    FROM 
        aka_title a
    LEFT JOIN 
        complete_cast cc ON a.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    WHERE 
        a.production_year IS NOT NULL
), CompanyMovies AS (
    SELECT 
        m.movie_id,
        co.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies m
    JOIN 
        company_name co ON m.company_id = co.id
    JOIN 
        company_type ct ON m.company_type_id = ct.id
), PopularMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        cm.company_name,
        cm.company_type,
        rm.cast_count
    FROM 
        RankedMovies rm
    LEFT JOIN 
        CompanyMovies cm ON rm.movie_id = cm.movie_id
    WHERE 
        rm.rank_year <= 10 AND rm.cast_count > 5
)

SELECT 
    pm.title,
    pm.production_year,
    COALESCE(pm.company_name, 'Independent') AS company_name,
    pm.company_type,
    CONCAT('Cast Count: ', pm.cast_count) AS formulated_cast_info
FROM 
    PopularMovies pm
ORDER BY 
    pm.production_year DESC, pm.cast_count DESC;
