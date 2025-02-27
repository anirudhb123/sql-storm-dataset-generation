WITH RankedMovies AS (
    SELECT 
        at.title AS movie_title,
        at.production_year,
        ak.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY at.id ORDER BY ak.name) AS actor_rank
    FROM 
        aka_title at
    JOIN 
        cast_info ci ON at.id = ci.movie_id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        at.production_year >= 2000
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
MovieDetails AS (
    SELECT 
        rm.movie_title,
        rm.production_year,
        rm.actor_name,
        mk.keywords
    FROM 
        RankedMovies rm
    LEFT JOIN 
        MovieKeywords mk ON rm.movie_title = mk.movie_id
)
SELECT 
    MD.movie_title,
    MD.production_year,
    MD.actor_name,
    MD.keywords,
    COUNT(DISTINCT md.id) AS num_movie_details
FROM 
    MovieDetails MD
JOIN 
    movie_info md ON md.movie_id = (SELECT id FROM aka_title WHERE title = MD.movie_title LIMIT 1)
GROUP BY 
    MD.movie_title, MD.production_year, MD.actor_name, MD.keywords
ORDER BY 
    MD.production_year DESC, MD.movie_title;
