WITH RankedTitles AS (
    SELECT 
        at.title,
        at.production_year,
        at.kind_id,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.production_year DESC) as rn
    FROM
        aka_title at
    WHERE
        at.production_year BETWEEN 2000 AND 2020
),
ActorCount AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),
TopActors AS (
    SELECT
        ak.name AS actor_name,
        COUNT(DISTINCT ci.movie_id) AS movies_starred
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    GROUP BY 
        ak.name 
    HAVING 
        COUNT(DISTINCT ci.movie_id) >= 5
),
MovieCompanies AS (
    SELECT
        mc.movie_id,
        STRING_AGG(cn.name, ', ') AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    rt.title,
    rt.production_year,
    tc.actor_name,
    ac.actor_count,
    mc.company_names
FROM 
    RankedTitles rt
LEFT JOIN 
    ActorCount ac ON rt.id = ac.movie_id
LEFT JOIN 
    TopActors tc ON tc.movies_starred > 5
LEFT JOIN 
    MovieCompanies mc ON mc.movie_id = rt.id
WHERE 
    rt.rn = 1
ORDER BY 
    rt.production_year DESC, tc.actor_name ASC
LIMIT 100;
