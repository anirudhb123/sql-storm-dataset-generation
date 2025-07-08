WITH RankedMovies AS (
    SELECT 
        mt.title,
        mt.production_year,
        COUNT(DISTINCT mc.company_id) AS company_count,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY COUNT(DISTINCT mc.company_id) DESC) AS rank
    FROM 
        aka_title mt
    JOIN 
        movie_companies mc ON mt.id = mc.movie_id
    GROUP BY 
        mt.title, mt.production_year
), 
ActorRoles AS (
    SELECT 
        ak.name AS actor_name,
        ct.kind AS role_name,
        COUNT(ci.movie_id) AS movie_count
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    JOIN 
        comp_cast_type ct ON ci.person_role_id = ct.id
    GROUP BY 
        ak.name, ct.kind
), 
TopActors AS (
    SELECT 
        actor_name,
        SUM(movie_count) OVER (ORDER BY movie_count DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total
    FROM 
        ActorRoles
)
SELECT 
    rm.title,
    rm.production_year,
    rm.company_count,
    ta.actor_name,
    ta.running_total
FROM 
    RankedMovies rm
LEFT JOIN 
    TopActors ta ON ta.running_total < 5
ORDER BY 
    rm.production_year DESC, 
    rm.company_count DESC;
