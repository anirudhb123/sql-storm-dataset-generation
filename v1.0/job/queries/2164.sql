
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
        STRING_AGG(DISTINCT ak.name, ', ') AS cast_names
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        ci.movie_id
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS total_companies,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
FinalDetails AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        cd.total_cast,
        cd.cast_names,
        co.total_companies,
        co.company_names
    FROM 
        RankedMovies rm
    LEFT JOIN 
        CastDetails cd ON rm.movie_id = cd.movie_id
    LEFT JOIN 
        CompanyDetails co ON rm.movie_id = co.movie_id
)
SELECT 
    fd.title,
    fd.production_year,
    COALESCE(fd.total_cast, 0) AS total_cast,
    COALESCE(fd.cast_names, 'No Cast') AS cast_names,
    COALESCE(fd.total_companies, 0) AS total_companies,
    COALESCE(fd.company_names, 'No Companies') AS company_names,
    rm.title_rank
FROM 
    FinalDetails fd
JOIN 
    RankedMovies rm ON fd.movie_id = rm.movie_id
WHERE 
    fd.production_year >= 2000
AND 
    (fd.total_cast IS NULL OR fd.total_cast > 1)
ORDER BY 
    fd.production_year DESC, 
    rm.title_rank ASC;
