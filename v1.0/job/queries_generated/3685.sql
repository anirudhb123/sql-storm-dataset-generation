WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.production_year DESC) AS rank_year
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL
),
CastDetails AS (
    SELECT 
        ci.movie_id,
        ka.name AS actor_name,
        ka.person_id,
        RANK() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS actor_rank
    FROM 
        cast_info ci
    JOIN 
        aka_name ka ON ci.person_id = ka.person_id
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
TitlesWithHighestKeywords AS (
    SELECT 
        mt.id AS movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    GROUP BY 
        mt.id
    HAVING 
        COUNT(mk.keyword_id) > 0
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    cd.actor_name,
    cd.actor_rank,
    co.company_name,
    co.company_type,
    tw.keyword_count
FROM 
    RankedMovies rm
LEFT JOIN 
    CastDetails cd ON rm.movie_id = cd.movie_id
LEFT JOIN 
    CompanyDetails co ON rm.movie_id = co.movie_id
LEFT JOIN 
    TitlesWithHighestKeywords tw ON rm.movie_id = tw.movie_id
WHERE 
    rm.rank_year <= 5 
    AND (co.company_type IS NULL OR co.company_type != 'Distributor')
ORDER BY 
    rm.production_year DESC, 
    cd.actor_rank, 
    co.company_name
LIMIT 100;
