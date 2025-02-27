WITH RecursiveMovieHierarchy AS (
    SELECT 
        mt.id,
        mt.title,
        mt.production_year,
        mt.imdb_index,
        mt.kind_id,
        0 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.production_year > 2000
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        mt.title,
        mt.production_year,
        mt.imdb_index,
        mt.kind_id,
        rm.depth + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title mt ON ml.movie_id = mt.id
    JOIN 
        RecursiveMovieHierarchy rm ON rm.id = ml.movie_id
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
ActorInfo AS (
    SELECT 
        ci.movie_id,
        ARRAY_AGG(DISTINCT a.name) AS actors
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    GROUP BY 
        ci.movie_id
),
PopularMovies AS (
    SELECT 
        r.title,
        r.production_year,
        r.depth,
        COALESCE(mk.keywords, 'No keywords') AS keywords,
        COALESCE(ai.actors, ARRAY['No actors']) AS actors
    FROM 
        RecursiveMovieHierarchy r
    LEFT JOIN 
        MovieKeywords mk ON r.id = mk.movie_id
    LEFT JOIN 
        ActorInfo ai ON r.id = ai.movie_id
    WHERE 
        r.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE 'movie%')
    AND 
        r.depth < 3
)
SELECT 
    pm.title,
    pm.production_year,
    pm.keywords,
    pm.actors,
    CASE 
        WHEN pm.production_year BETWEEN 2020 AND 2023 THEN 'Recent'
        WHEN pm.production_year < 2020 THEN 'Older'
        ELSE 'Unknown Year'
    END AS time_frame
FROM 
    PopularMovies pm
WHERE 
    pm.actors IS NOT NULL
ORDER BY 
    pm.production_year DESC,
    pm.title ASC;
