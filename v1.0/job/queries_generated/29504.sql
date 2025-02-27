WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS num_actors,
        ARRAY_AGG(DISTINCT ak.name) AS actor_names
    FROM 
        aka_title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        t.id, t.title, t.production_year
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
        rm.title,
        rm.production_year,
        rm.num_actors,
        rm.actor_names,
        mk.keywords
    FROM 
        RankedMovies rm
    LEFT JOIN 
        MovieKeywords mk ON rm.movie_id = mk.movie_id
)

SELECT 
    cmi.title,
    cmi.production_year,
    cmi.num_actors,
    COALESCE(cmi.keywords, 'No Keywords') AS keywords,
    cmi.actor_names
FROM 
    CompleteMovieInfo cmi
WHERE 
    cmi.production_year >= 2000 
ORDER BY 
    cmi.num_actors DESC, cmi.production_year ASC;
