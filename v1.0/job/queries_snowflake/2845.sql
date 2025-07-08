
WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.title) AS title_rank
    FROM 
        aka_title a
    JOIN 
        movie_info mi ON a.movie_id = mi.movie_id
    WHERE 
        mi.info_type_id = (SELECT id FROM info_type WHERE info = 'tagline')
),
DistinctCompanies AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        ROW_NUMBER() OVER (PARTITION BY mc.movie_id ORDER BY c.name) AS company_rank
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    WHERE 
        c.country_code IS NOT NULL
),
MovieCast AS (
    SELECT 
        c.movie_id,
        COUNT(c.id) AS total_cast,
        LISTAGG(DISTINCT CONCAT(a.name, ' (', r.role, ')'), ', ') WITHIN GROUP (ORDER BY a.name) AS cast_details
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.movie_id
),
FinalResult AS (
    SELECT 
        rm.title,
        rm.production_year,
        dc.company_name,
        dc.company_type,
        mc.total_cast,
        mc.cast_details
    FROM 
        RankedMovies rm
    LEFT JOIN 
        DistinctCompanies dc ON rm.movie_id = dc.movie_id AND dc.company_rank = 1
    LEFT JOIN 
        MovieCast mc ON rm.movie_id = mc.movie_id
    WHERE 
        rm.title_rank <= 5
)
SELECT 
    title,
    production_year,
    COALESCE(company_name, 'Unknown Company') AS company_name,
    COALESCE(company_type, 'N/A') AS company_type,
    COALESCE(total_cast, 0) AS total_cast,
    COALESCE(cast_details, 'No cast available') AS cast_details
FROM 
    FinalResult
ORDER BY 
    production_year DESC, title;
