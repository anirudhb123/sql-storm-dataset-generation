WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        RANK() OVER (PARTITION BY mt.production_year ORDER BY mt.id) AS rank_by_year
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('movie', 'tv series'))
),
FilteredCast AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM 
        cast_info ci
    JOIN 
        person_info pi ON ci.person_id = pi.person_id
    WHERE 
        pi.info LIKE '%actor%'
    GROUP BY 
        ci.movie_id
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id, cn.name, ct.kind
)
SELECT 
    rm.title,
    rm.production_year,
    COALESCE(fc.cast_count, 0) AS cast_count,
    COALESCE(cd.company_count, 0) AS company_count,
    STRING_AGG(cd.company_name, ', ') AS companies
FROM 
    RankedMovies rm
LEFT JOIN 
    FilteredCast fc ON rm.movie_id = fc.movie_id
LEFT JOIN 
    CompanyDetails cd ON rm.movie_id = cd.movie_id
WHERE 
    rm.rank_by_year <= 5
GROUP BY 
    rm.movie_id, rm.title, rm.production_year, fc.cast_count, cd.company_count
HAVING 
    COALESCE(fc.cast_count, 0) > 0 OR COALESCE(cd.company_count, 0) > 0
ORDER BY 
    rm.production_year DESC, rm.title;
