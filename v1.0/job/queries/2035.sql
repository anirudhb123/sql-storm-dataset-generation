WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(c.id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.id) DESC) AS rn
    FROM 
        title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.person_id
    GROUP BY 
        t.id, t.title, t.production_year
),
HighCastMovies AS (
    SELECT
        rm.title,
        rm.production_year,
        rm.cast_count
    FROM 
        RankedMovies rm
    WHERE 
        rm.cast_count >= 5
),
CompanyMovieInfo AS (
    SELECT 
        m.title,
        cn.name AS company_name,
        ct.kind AS company_type,
        m.production_year,
        COALESCE(mi.info, 'No Info Available') AS additional_info
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    JOIN 
        title m ON mc.movie_id = m.id
    LEFT JOIN 
        movie_info mi ON m.id = mi.movie_id AND mi.info_type_id = 1
)
SELECT 
    hcm.title,
    hcm.production_year,
    hcm.cast_count,
    cmi.company_name,
    cmi.company_type,
    cmi.additional_info
FROM 
    HighCastMovies hcm
LEFT JOIN 
    CompanyMovieInfo cmi ON hcm.title = cmi.title AND hcm.production_year = cmi.production_year
WHERE 
    (cmi.company_type IS NOT NULL OR cmi.additional_info IS NOT NULL)
ORDER BY 
    hcm.production_year DESC, hcm.cast_count DESC;
