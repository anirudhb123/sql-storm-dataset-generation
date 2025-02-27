
WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        ak.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY mt.id ORDER BY ak.name) AS actor_rank
    FROM 
        aka_title mt
    JOIN 
        cast_info ci ON mt.id = ci.movie_id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        mt.production_year > 2000
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
CompleteMovieInfo AS (
    SELECT 
        rm.movie_id,
        rm.movie_title,
        rm.production_year,
        rm.actor_name,
        mk.keywords
    FROM 
        RankedMovies rm
    LEFT JOIN 
        MovieKeywords mk ON rm.movie_id = mk.movie_id
)
SELECT 
    cm.movie_title,
    cm.production_year,
    ARRAY_AGG(DISTINCT cm.actor_name) AS actors,
    cm.keywords
FROM 
    CompleteMovieInfo cm
GROUP BY 
    cm.movie_title, cm.production_year, cm.keywords
ORDER BY 
    cm.production_year DESC, cm.movie_title;
