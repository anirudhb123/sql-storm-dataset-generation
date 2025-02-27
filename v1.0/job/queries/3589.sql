
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        DENSE_RANK() OVER (PARTITION BY t.production_year ORDER BY t.id) AS rank_within_year
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorDetails AS (
    SELECT 
        a.id AS person_id,
        a.name AS actor_name,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.id = ci.person_id
    GROUP BY 
        a.id, a.name
    HAVING 
        COUNT(DISTINCT ci.movie_id) > 5
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        ROW_NUMBER() OVER (PARTITION BY mc.movie_id ORDER BY c.name) AS comp_rank
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
MovieCast AS (
    SELECT 
        ci.movie_id,
        STRING_AGG(a.name, ', ') AS cast_names
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.id
    GROUP BY 
        ci.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    ad.actor_name,
    ad.movie_count,
    ci.company_name,
    ci.company_type,
    mc.cast_names
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorDetails ad ON rm.movie_id IN (
        SELECT movie_id 
        FROM cast_info 
        WHERE person_id = ad.person_id
    )
LEFT JOIN 
    CompanyInfo ci ON rm.movie_id = ci.movie_id AND ci.comp_rank = 1
LEFT JOIN 
    MovieCast mc ON rm.movie_id = mc.movie_id
WHERE 
    rm.rank_within_year <= 10
ORDER BY 
    rm.production_year DESC, 
    rm.title;
