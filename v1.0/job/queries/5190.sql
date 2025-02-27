WITH RankedMovies AS (
    SELECT 
        t.title, 
        t.production_year, 
        COUNT(DISTINCT c.person_id) AS cast_count, 
        AVG(pi.info_type_id) AS avg_info_type 
    FROM 
        title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.id
    LEFT JOIN 
        movie_info mi ON t.id = mi.movie_id
    LEFT JOIN 
        person_info pi ON c.person_id = pi.person_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
), CompanyDetails AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT cn.id) AS company_count,
        STRING_AGG(DISTINCT cn.name, '; ') AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    rm.cast_count,
    rm.avg_info_type,
    cd.company_count,
    cd.company_names
FROM 
    RankedMovies rm
LEFT JOIN 
    CompanyDetails cd ON rm.production_year = cd.movie_id
ORDER BY 
    rm.cast_count DESC, rm.production_year ASC
LIMIT 100;
