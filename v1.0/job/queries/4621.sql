
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank_within_year
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorMovieCounts AS (
    SELECT 
        c.person_id,
        COUNT(DISTINCT c.movie_id) AS movie_count
    FROM 
        cast_info c
    JOIN 
        RankedMovies rm ON c.movie_id = rm.movie_id
    GROUP BY 
        c.person_id
),
MostActiveActors AS (
    SELECT 
        a.person_id,
        a.name,
        amc.movie_count
    FROM 
        aka_name a
    INNER JOIN 
        ActorMovieCounts amc ON a.person_id = amc.person_id
    WHERE 
        amc.movie_count > 5
),
MoviesWithKeywords AS (
    SELECT 
        m.id AS movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id
)
SELECT 
    ma.person_id AS actor_id,
    ma.name AS actor_name,
    rm.title AS movie_title,
    rm.production_year,
    mwk.keywords
FROM 
    MostActiveActors ma
JOIN 
    RankedMovies rm ON ma.person_id = rm.movie_id
LEFT JOIN 
    MoviesWithKeywords mwk ON rm.movie_id = mwk.movie_id
WHERE 
    rm.rank_within_year <= 10
ORDER BY 
    ma.name,
    rm.production_year DESC;
