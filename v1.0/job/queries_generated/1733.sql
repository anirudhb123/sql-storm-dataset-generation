WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.id) AS rn
    FROM 
        title m
    WHERE 
        m.production_year IS NOT NULL
),
ActorsInMovies AS (
    SELECT 
        a.person_id,
        a.name,
        COUNT(DISTINCT c.movie_id) AS movie_count
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    GROUP BY 
        a.person_id, a.name
    HAVING 
        COUNT(DISTINCT c.movie_id) > 3
),
MovieKeywords AS (
    SELECT 
        m.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword m
    JOIN 
        keyword k ON m.keyword_id = k.id
    GROUP BY 
        m.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    ak.name AS actor_name,
    ak.movie_count,
    mk.keywords
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorsInMovies ak ON rm.movie_id = ak.movie_id
LEFT JOIN 
    MovieKeywords mk ON rm.movie_id = mk.movie_id
WHERE 
    (rm.production_year > 2000 AND rm.rn <= 10)
    OR (ak.movie_count IS NOT NULL AND ak.movie_count > 5)
ORDER BY 
    rm.production_year DESC, rm.title;
