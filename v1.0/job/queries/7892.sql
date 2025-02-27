WITH RankedMovies AS (
    SELECT 
        at.title,
        at.production_year,
        COUNT(DISTINCT mc.company_id) AS company_count,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(DISTINCT mc.company_id) DESC) AS rank
    FROM 
        aka_title at
    JOIN 
        movie_companies mc ON at.id = mc.movie_id
    WHERE 
        at.production_year >= 2000
    GROUP BY 
        at.id, at.title, at.production_year
), ActorDetails AS (
    SELECT 
        ak.name AS actor_name,
        at.title AS movie_title,
        at.production_year,
        ci.nr_order,
        co.kind AS role
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    JOIN 
        aka_title at ON ci.movie_id = at.id
    JOIN 
        comp_cast_type co ON ci.person_role_id = co.id
)
SELECT 
    rm.title,
    rm.production_year,
    rm.company_count,
    ad.actor_name,
    ad.nr_order,
    ad.role
FROM 
    RankedMovies rm
JOIN 
    ActorDetails ad ON rm.title = ad.movie_title AND rm.production_year = ad.production_year
WHERE 
    rm.rank = 1
ORDER BY 
    rm.production_year DESC, rm.company_count DESC;
