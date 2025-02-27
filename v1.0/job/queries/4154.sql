WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
CastDetails AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    GROUP BY 
        ci.movie_id
),
CompanyDetails AS (
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
        mi.info AS movie_note
    FROM 
        movie_info mi
    WHERE 
        mi.info_type_id = (SELECT id FROM info_type WHERE info = 'summary')
),
FinalReport AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        COALESCE(cd.total_cast, 0) AS total_cast,
        COALESCE(cd.cast_names, 'No cast available') AS cast_names,
        COALESCE(cd.total_cast, 0) * 1.0 / NULLIF(rm.title_rank, 0) AS cast_to_title_rank_ratio,
        coalesce(ci.movie_note, 'No additional info available') as movie_note
    FROM 
        RankedMovies rm
    LEFT JOIN 
        CastDetails cd ON rm.movie_id = cd.movie_id
    LEFT JOIN 
        MovieInfo ci ON rm.movie_id = ci.movie_id
)
SELECT 
    *
FROM 
    FinalReport
WHERE 
    production_year >= 2000
ORDER BY 
    total_cast DESC, production_year ASC
LIMIT 50;
