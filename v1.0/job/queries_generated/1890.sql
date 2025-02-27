WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(ci.id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.id) DESC) AS rn
    FROM 
        title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    GROUP BY 
        t.title, t.production_year
),
HigherCastCount AS (
    SELECT 
        production_year,
        title
    FROM 
        RankedMovies
    WHERE 
        rn = 1
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type,
        COUNT(mc.id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id, cn.name, ct.kind
)
SELECT 
    hm.title,
    hm.production_year,
    hm.cast_count,
    COALESCE(cd.company_name, 'Not Available') AS company_name,
    COALESCE(cd.company_type, 'Not Available') AS company_type,
    COALESCE(cd.company_count, 0) AS company_count
FROM 
    HigherCastCount hm
LEFT JOIN 
    CompanyDetails cd ON hm.title = cd.movie_id 
WHERE 
    hm.production_year IN (
        SELECT 
            DISTINCT production_year 
        FROM 
            RankedMovies 
        WHERE 
            cast_count > 10
    )
ORDER BY 
    hm.production_year DESC, 
    hm.cast_count DESC;
