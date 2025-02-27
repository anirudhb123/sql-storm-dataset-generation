WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rank_per_year
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorMovieCount AS (
    SELECT 
        ci.person_id,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.person_id
),
ActorNames AS (
    SELECT 
        ak.person_id,
        STRING_AGG(ak.name, ', ') AS actor_names
    FROM 
        aka_name ak
    GROUP BY 
        ak.person_id
)
SELECT 
    rm.title,
    rm.production_year,
    ac.actor_names,
    amc.movie_count,
    COUNT(DISTINCT mk.keyword) AS keyword_count
FROM 
    RankedMovies rm
LEFT JOIN 
    complete_cast cc ON rm.movie_id = cc.movie_id
LEFT JOIN 
    ActorMovieCount amc ON cc.subject_id = amc.person_id
LEFT JOIN 
    ActorNames ac ON amc.person_id = ac.person_id
LEFT JOIN 
    movie_keyword mk ON rm.movie_id = mk.movie_id
WHERE 
    rm.rank_per_year <= 5 AND
    (amc.movie_count IS NULL OR amc.movie_count > 2)
GROUP BY 
    rm.movie_id, rm.title, rm.production_year, ac.actor_names, amc.movie_count
ORDER BY 
    rm.production_year DESC, keyword_count DESC;
