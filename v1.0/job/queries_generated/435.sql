WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.production_year DESC) AS year_rank
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = 1
),
ActorsInMovies AS (
    SELECT 
        a.id AS actor_id,
        a.name,
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) OVER (PARTITION BY ci.movie_id) AS actor_count
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    ak.name AS main_actor,
    ak.actor_count,
    COALESCE(mk.keywords, 'No Keywords') AS keywords
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorsInMovies ak ON rm.movie_id = ak.movie_id AND ak.actor_count > 2
LEFT JOIN 
    MovieKeywords mk ON rm.movie_id = mk.movie_id
WHERE 
    rm.year_rank <= 5
ORDER BY 
    rm.production_year DESC, ak.actor_count DESC NULLS LAST;
