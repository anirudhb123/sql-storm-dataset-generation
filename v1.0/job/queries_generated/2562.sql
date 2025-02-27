WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorMovieCounts AS (
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
        STRING_AGG(DISTINCT ak.name, ', ') AS actor_names
    FROM 
        aka_name ak
    INNER JOIN 
        ActorMovieCounts am ON ak.person_id = am.person_id
    GROUP BY 
        ak.person_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    an.actor_names,
    am.movie_count,
    COUNT(DISTINCT mk.keyword) AS keyword_count
FROM 
    RankedMovies rm
LEFT JOIN 
    complete_cast cc ON rm.movie_id = cc.movie_id
LEFT JOIN 
    ActorNames an ON cc.subject_id = an.person_id
LEFT JOIN 
    movie_keyword mk ON rm.movie_id = mk.movie_id
JOIN 
    ActorMovieCounts am ON an.person_id = am.person_id
WHERE 
    rm.rank <= 5 AND
    (am.movie_count > 1 OR am.movie_count IS NULL)
GROUP BY 
    rm.movie_id, rm.title, rm.production_year, an.actor_names, am.movie_count
ORDER BY 
    rm.production_year DESC, rm.title ASC;
