WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.person_id) DESC) AS rank
    FROM 
        title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
ActorAwards AS (
    SELECT 
        ak.person_id,
        ak.name,
        COUNT(DISTINCT cc.movie_id) AS movie_count,
        SUM(CASE WHEN ti.info LIKE '%Award%' THEN 1 ELSE 0 END) AS awards
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    JOIN 
        complete_cast cc ON ci.movie_id = cc.movie_id
    JOIN 
        movie_info ti ON cc.movie_id = ti.movie_id
    WHERE 
        ti.note IS NOT NULL
    GROUP BY 
        ak.person_id, ak.name
),
MostActiveActors AS (
    SELECT 
        aa.person_id,
        aa.name,
        aa.movie_count,
        RANK() OVER (ORDER BY aa.movie_count DESC) AS active_rank
    FROM 
        ActorAwards aa
)
SELECT 
    rm.title,
    rm.production_year,
    maa.name AS actor_name,
    maa.movie_count,
    maa.awards
FROM 
    RankedMovies rm
JOIN 
    MostActiveActors maa ON rm.movie_id IN (
        SELECT 
            cc.movie_id 
        FROM 
            cast_info cc 
        WHERE 
            cc.person_id = maa.person_id
    )
WHERE 
    rm.rank = 1
ORDER BY 
    rm.production_year DESC, 
    maa.movie_count DESC;
