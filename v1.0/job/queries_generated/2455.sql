WITH MovieDetails AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        STRING_AGG(DISTINCT an.name, ', ') AS actor_names
    FROM 
        aka_title mt
    LEFT JOIN 
        cast_info ci ON mt.id = ci.movie_id
    LEFT JOIN 
        aka_name an ON ci.person_id = an.person_id
    WHERE 
        mt.production_year IS NOT NULL
    GROUP BY 
        mt.id, mt.title, mt.production_year
),
CompanyDetails AS (
    SELECT
        mc.movie_id,
        GROUP_CONCAT(DISTINCT cn.name) AS companies,
        COUNT(DISTINCT mc.company_id) AS total_companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    WHERE 
        cn.country_code = 'USA'
    GROUP BY 
        mc.movie_id
),
RankedMovies AS (
    SELECT
        md.*,
        cd.companies,
        cd.total_companies,
        ROW_NUMBER() OVER (PARTITION BY md.production_year ORDER BY md.total_cast DESC) AS rank
    FROM 
        MovieDetails md
    LEFT JOIN 
        CompanyDetails cd ON md.movie_id = cd.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.total_cast,
    rm.companies,
    rm.total_companies,
    rm.rank
FROM 
    RankedMovies rm
WHERE 
    (rm.total_cast IS NOT NULL AND rm.total_cast > 0)
    OR (rm.total_companies IS NOT NULL AND rm.total_companies > 0)
ORDER BY 
    rm.production_year DESC, rm.rank
LIMIT 100;
