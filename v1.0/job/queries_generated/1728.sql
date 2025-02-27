WITH RankedMovies AS (
    SELECT 
        at.id AS movie_id, 
        at.title, 
        at.production_year, 
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.production_year DESC) AS rank_year
    FROM 
        aka_title at
    WHERE 
        at.production_year IS NOT NULL
),
CastDetails AS (
    SELECT 
        ci.movie_id, 
        COUNT(ci.person_id) AS total_cast,
        STRING_AGG(DISTINCT ak.name, ', ') AS cast_names
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        ci.movie_id
),
MovieCompanies AS (
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
)
SELECT 
    rm.movie_id, 
    rm.title, 
    rm.production_year, 
    cd.total_cast,
    cd.cast_names,
    COALESCE(mco.company_name, 'Independent') AS production_company,
    COALESCE(mco.company_type, 'N/A') AS kind_of_company
FROM 
    RankedMovies rm
LEFT JOIN 
    CastDetails cd ON rm.movie_id = cd.movie_id
LEFT JOIN 
    MovieCompanies mco ON rm.movie_id = mco.movie_id
WHERE 
    rm.rank_year <= 10
ORDER BY 
    rm.production_year DESC, cd.total_cast DESC;
