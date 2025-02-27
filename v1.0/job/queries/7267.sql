WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY t.id) AS rank_within_year
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    WHERE 
        mk.keyword_id IN (SELECT id FROM keyword WHERE keyword LIKE '%action%')
),
ActorDetails AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        a.id AS actor_id,
        RANK() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS actor_rank
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
),
MovieCompanies AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    ad.actor_name,
    ad.actor_rank,
    mc.companies
FROM 
    RankedMovies rm
JOIN 
    ActorDetails ad ON rm.movie_id = ad.movie_id
JOIN 
    MovieCompanies mc ON rm.movie_id = mc.movie_id
WHERE 
    rm.rank_within_year <= 5 AND ad.actor_rank <= 3
ORDER BY 
    rm.production_year DESC, rm.title;
