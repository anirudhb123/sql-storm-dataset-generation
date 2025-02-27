WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
MovieCast AS (
    SELECT 
        c.movie_id,
        COUNT(c.person_id) AS cast_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actors
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
        cn.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
MovieDetails AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        COALESCE(mc.cast_count, 0) AS cast_count,
        COALESCE(mc.actors, 'No Cast') AS actors,
        ci.company_name,
        ci.company_type
    FROM 
        RankedMovies rm
    LEFT JOIN 
        MovieCast mc ON rm.movie_id = mc.movie_id
    LEFT JOIN 
        CompanyInfo ci ON rm.movie_id = ci.movie_id
    WHERE 
        rm.rank <= 5
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.cast_count,
    md.actors,
    md.company_name,
    md.company_type
FROM 
    MovieDetails md
WHERE 
    md.production_year >= 2000
ORDER BY 
    md.production_year DESC, 
    md.title ASC;
