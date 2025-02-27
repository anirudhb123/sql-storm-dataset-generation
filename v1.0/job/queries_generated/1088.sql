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
MovieGenres AS (
    SELECT 
        mt.movie_id,
        STRING_AGG(DISTINCT kt.keyword, ', ') AS genres
    FROM 
        movie_keyword mk
    JOIN 
        keyword kt ON mk.keyword_id = kt.id
    GROUP BY 
        mt.movie_id
),
CastDetails AS (
    SELECT 
        ci.movie_id,
        ARRAY_AGG(DISTINCT CONCAT(an.name, ' as ', rt.role)) AS cast_list
    FROM 
        cast_info ci
    JOIN 
        aka_name an ON ci.person_id = an.person_id
    JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        ci.movie_id
),
MovieCompanies AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, '; ') AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    COALESCE(mg.genres, 'No Genres') AS genres,
    COALESCE(cd.cast_list, ARRAY['No Cast']) AS cast_list,
    COALESCE(comp.companies, 'No Companies') AS companies
FROM 
    RankedMovies rm
LEFT JOIN 
    MovieGenres mg ON rm.movie_id = mg.movie_id
LEFT JOIN 
    CastDetails cd ON rm.movie_id = cd.movie_id
LEFT JOIN 
    MovieCompanies comp ON rm.movie_id = comp.movie_id
WHERE 
    rm.rank <= 5
ORDER BY 
    rm.production_year DESC, rm.movie_id ASC;
