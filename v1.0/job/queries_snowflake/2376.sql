
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rank_year
    FROM title t
    WHERE t.production_year IS NOT NULL
),

ActorStats AS (
    SELECT 
        ak.id AS actor_id,
        ak.name,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        AVG(NULLIF(ti.production_year, '')) AS avg_production_year
    FROM aka_name ak
    JOIN cast_info ci ON ak.person_id = ci.person_id
    LEFT JOIN title ti ON ci.movie_id = ti.id
    GROUP BY ak.id, ak.name
),

TopActors AS (
    SELECT 
        actor_id,
        name,
        movie_count,
        avg_production_year,
        RANK() OVER (ORDER BY movie_count DESC) AS actor_rank
    FROM ActorStats
),

MovieCompanyInfo AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT co.name) AS company_count,
        LISTAGG(DISTINCT co.name, ', ') WITHIN GROUP (ORDER BY co.name) AS companies
    FROM movie_companies mc
    JOIN company_name co ON mc.company_id = co.id
    GROUP BY mc.movie_id
)

SELECT 
    tm.title,
    tm.production_year,
    ta.name AS top_actor,
    ta.movie_count,
    ta.avg_production_year,
    mc.company_count,
    mc.companies
FROM RankedMovies tm
LEFT JOIN TopActors ta ON tm.rank_year = 1 AND ta.actor_rank <= 10 
LEFT JOIN MovieCompanyInfo mc ON tm.movie_id = mc.movie_id
WHERE 
    (mc.company_count > 1 OR mc.company_count IS NULL)
    AND (tm.production_year IS NULL OR tm.production_year > 2000)
ORDER BY 
    tm.production_year DESC, 
    ta.movie_count DESC;
