WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorAwards AS (
    SELECT 
        ca.person_id,
        COUNT(DISTINCT m.id) AS award_count
    FROM 
        cast_info ca
    JOIN 
        complete_cast cc ON ca.movie_id = cc.movie_id
    JOIN 
        aka_title m ON cc.movie_id = m.id
    WHERE 
        m.kind_id IN (1, 2) -- Assuming 1 = Feature Film, 2 = TV Movies
    GROUP BY 
        ca.person_id
),
TopActors AS (
    SELECT 
        ak.name,
        aa.award_count,
        RANK() OVER (ORDER BY aa.award_count DESC) AS actor_rank
    FROM 
        ActorAwards aa
    JOIN 
        aka_name ak ON aa.person_id = ak.person_id
    WHERE 
        aa.award_count > 0
)
SELECT 
    rm.title,
    rm.production_year,
    ta.name AS top_actor,
    ta.award_count
FROM 
    RankedMovies rm
LEFT JOIN 
    TopActors ta ON rm.rank = 1
WHERE 
    rm.production_year >= 2000
ORDER BY 
    rm.production_year DESC, 
    ta.award_count DESC
LIMIT 100;
