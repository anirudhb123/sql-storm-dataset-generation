WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        a.id AS movie_id,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC, a.title) AS rank
    FROM aka_title a
    WHERE a.production_year IS NOT NULL
),
CompanyStats AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT c.id) AS num_companies,
        STRING_AGG(DISTINCT co.name, ', ') AS companies
    FROM movie_companies mc
    JOIN company_name co ON mc.company_id = co.id
    GROUP BY mc.movie_id
),
ActorStats AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT a.id) AS num_actors
    FROM cast_info ci
    JOIN aka_name a ON ci.person_id = a.person_id
    GROUP BY ci.movie_id
),
CombinedStats AS (
    SELECT 
        rm.title, 
        rm.production_year,
        cs.num_companies, 
        as.num_actors
    FROM RankedMovies rm
    LEFT JOIN CompanyStats cs ON rm.movie_id = cs.movie_id
    LEFT JOIN ActorStats as ON rm.movie_id = as.movie_id
)
SELECT 
    title, 
    production_year,
    COALESCE(num_companies, 0) AS total_companies,
    COALESCE(num_actors, 0) AS total_actors
FROM CombinedStats
WHERE num_companies > 0 OR num_actors IS NOT NULL
ORDER BY production_year DESC, title;
