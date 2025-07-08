
WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.title) AS rank_by_year
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL
),
CastInfoDetails AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        LISTAGG(DISTINCT n.name, ', ') WITHIN GROUP (ORDER BY n.name) AS cast_names
    FROM 
        cast_info ci
    JOIN 
        name n ON ci.person_id = n.imdb_id
    GROUP BY 
        ci.movie_id
),
MovieCompanyInfo AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS total_companies,
        LISTAGG(DISTINCT cn.name, ', ') WITHIN GROUP (ORDER BY cn.name) AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.imdb_id
    GROUP BY 
        mc.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    COALESCE(cd.total_cast, 0) AS total_cast_members,
    COALESCE(cd.cast_names, 'No Cast Available') AS cast_member_names,
    COALESCE(cmp.total_companies, 0) AS total_companies_involved,
    COALESCE(cmp.company_names, 'No Companies') AS company_names_involved
FROM 
    RankedMovies rm
LEFT JOIN 
    CastInfoDetails cd ON rm.movie_id = cd.movie_id
LEFT JOIN 
    MovieCompanyInfo cmp ON rm.movie_id = cmp.movie_id
WHERE 
    rm.rank_by_year <= 5 
ORDER BY 
    rm.production_year, rm.title;
