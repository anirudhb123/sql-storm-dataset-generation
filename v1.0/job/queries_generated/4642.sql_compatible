
WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, t.title) AS rn
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
MovieDetails AS (
    SELECT 
        rm.title_id,
        rm.title,
        rm.production_year,
        COUNT(c.movie_id) AS total_cast,
        STRING_AGG(DISTINCT CAST(c.id AS TEXT), ', ') AS cast_ids
    FROM 
        RankedMovies rm
    LEFT JOIN 
        cast_info c ON rm.title_id = c.movie_id
    GROUP BY 
        rm.title_id, rm.title, rm.production_year
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        co.name AS company_name,
        ct.kind AS company_type,
        COUNT(mc.id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id, co.name, ct.kind
),
FinalMovieStats AS (
    SELECT 
        md.title,
        md.production_year,
        COALESCE(cd.company_count, 0) AS company_count,
        md.total_cast,
        md.cast_ids
    FROM 
        MovieDetails md
    LEFT JOIN 
        CompanyDetails cd ON md.title_id = cd.movie_id
)
SELECT 
    fms.title,
    fms.production_year,
    fms.company_count,
    fms.total_cast,
    CASE 
        WHEN fms.total_cast > 0 THEN 'Cast available'
        ELSE 'No cast data'
    END AS cast_availability,
    fms.cast_ids
FROM 
    FinalMovieStats fms
WHERE 
    fms.production_year >= 2000
ORDER BY 
    fms.production_year DESC, 
    fms.title;
