WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank_by_title
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
MovieCast AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS total_cast,
        GROUP_CONCAT(DISTINCT a.name) AS cast_names
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        c.movie_id
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        GROUP_CONCAT(DISTINCT co.name) AS company_names,
        COUNT(DISTINCT co.id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    COALESCE(mc.total_cast, 0) AS total_cast,
    COALESCE(ci.company_count, 0) AS company_count,
    CASE 
        WHEN mc.total_cast IS NULL THEN 'No Cast Information'
        ELSE mc.cast_names
    END AS cast_details,
    CASE 
        WHEN ci.company_count = 0 THEN 'No Company Information'
        ELSE ci.company_names
    END AS company_details
FROM 
    RankedMovies rm
LEFT JOIN 
    MovieCast mc ON rm.movie_id = mc.movie_id
LEFT JOIN 
    CompanyInfo ci ON rm.movie_id = ci.movie_id
WHERE 
    rm.rank_by_title <= 5
ORDER BY 
    rm.production_year DESC, rm.title ASC;
