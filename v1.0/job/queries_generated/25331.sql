WITH RankedMovies AS (
    SELECT 
        mt.title AS movie_title,
        mt.production_year,
        ak.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY mt.id ORDER BY ak.name) AS actor_rank
    FROM 
        aka_title mt
    JOIN 
        movie_companies mc ON mc.movie_id = mt.id
    JOIN 
        cast_info ci ON ci.movie_id = mt.id
    JOIN 
        aka_name ak ON ak.person_id = ci.person_id
    WHERE 
        mt.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
        AND mt.production_year >= 2000
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON k.id = mk.keyword_id
    GROUP BY 
        mk.movie_id
),
EnhancedMovieInfo AS (
    SELECT 
        rm.movie_title,
        rm.production_year,
        rm.actor_name,
        mk.keywords
    FROM 
        RankedMovies rm
    LEFT JOIN 
        MovieKeywords mk ON mk.movie_id = rm.movie_id
)
SELECT 
    emi.movie_title,
    emi.production_year,
    emi.actor_name,
    emi.keywords,
    COUNT(emi.actor_name) OVER (PARTITION BY emi.movie_title) AS number_of_actors
FROM 
    EnhancedMovieInfo emi
WHERE 
    emi.actor_rank <= 5
ORDER BY 
    emi.production_year DESC, emi.movie_title;
