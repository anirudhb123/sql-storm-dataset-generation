WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year) AS year_rank
    FROM title t
    WHERE t.production_year IS NOT NULL
),
ActorCount AS (
    SELECT 
        c.movie_id,
        COUNT(c.person_id) AS actor_count
    FROM cast_info c
    GROUP BY c.movie_id
),
TopActors AS (
    SELECT 
        ak.name,
        mc.movie_id,
        COUNT(mc.company_id) AS company_count
    FROM aka_name ak
    JOIN cast_info ci ON ak.person_id = ci.person_id
    LEFT JOIN movie_companies mc ON ci.movie_id = mc.movie_id
    WHERE ak.name IS NOT NULL
    GROUP BY ak.name, mc.movie_id
    HAVING COUNT(mc.company_id) > 1
)
SELECT 
    rm.title,
    rm.production_year,
    ac.actor_count,
    ta.name AS top_actor,
    ta.company_count
FROM RankedMovies rm
LEFT JOIN ActorCount ac ON rm.movie_id = ac.movie_id
LEFT JOIN TopActors ta ON rm.movie_id = ta.movie_id
WHERE rm.year_rank <= 5 
AND (ta.company_count IS NULL OR ta.company_count > 0)
ORDER BY rm.production_year DESC, ac.actor_count DESC NULLS LAST, rm.title;
