
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rn
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
CastCounts AS (
    SELECT 
        ci.movie_id,
        COUNT(ci.id) AS cast_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),
CompanyMovies AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
MovieInfo AS (
    SELECT 
        mi.movie_id,
        LISTAGG(mii.info, ', ') WITHIN GROUP (ORDER BY mii.info) AS info_details
    FROM 
        movie_info mi
    JOIN 
        movie_info_idx mii ON mi.id = mii.movie_id
    GROUP BY 
        mi.movie_id
)

SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    COALESCE(cc.cast_count, 0) AS cast_count,
    COALESCE(cm.company_name, 'Unknown') AS company_name,
    COALESCE(cm.company_type, 'N/A') AS company_type,
    COALESCE(mi.info_details, 'No Info') AS info_details
FROM 
    RankedMovies rm
LEFT JOIN 
    CastCounts cc ON rm.movie_id = cc.movie_id
LEFT JOIN 
    CompanyMovies cm ON rm.movie_id = cm.movie_id
LEFT JOIN 
    MovieInfo mi ON rm.movie_id = mi.movie_id
WHERE 
    rm.rn <= 10
ORDER BY 
    rm.production_year DESC, rm.title ASC;
