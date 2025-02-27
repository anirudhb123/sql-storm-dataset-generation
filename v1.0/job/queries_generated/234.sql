WITH RankedMovies AS (
    SELECT 
        t.title, 
        t.production_year, 
        COUNT(DISTINCT c.person_id) OVER (PARTITION BY t.id) AS total_cast,
        ROW_NUMBER() OVER (ORDER BY t.production_year DESC, t.title) AS rn
    FROM 
        title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    WHERE 
        t.production_year IS NOT NULL
),
CompanyDetails AS (
    SELECT 
        mc.movie_id, 
        cn.name AS company_name, 
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
MovieInfo AS (
    SELECT 
        mi.movie_id, 
        STRING_AGG(DISTINCT mi.info, ', ') AS movie_notes
    FROM 
        movie_info mi
    GROUP BY 
        mi.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    rm.total_cast,
    cd.company_name,
    cd.company_type,
    COALESCE(mi.movie_notes, 'No Notes Available') AS notes
FROM 
    RankedMovies rm
LEFT JOIN 
    CompanyDetails cd ON rm.id = cd.movie_id
LEFT JOIN 
    MovieInfo mi ON rm.id = mi.movie_id
WHERE 
    rm.rn <= 50
ORDER BY 
    rm.production_year DESC, 
    rm.title ASC
LIMIT 100;
