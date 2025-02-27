WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id, 
        mt.title,
        mt.production_year,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS actors,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        aka_title mt
    LEFT JOIN 
        cast_info ci ON mt.id = ci.movie_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    GROUP BY 
        mt.id, mt.title, mt.production_year
)
SELECT 
    rm.movie_id, 
    rm.title, 
    rm.production_year, 
    rm.actor_count, 
    rm.actors, 
    rm.keywords 
FROM 
    RankedMovies rm 
WHERE 
    rm.rank <= 5 
ORDER BY 
    rm.production_year DESC, 
    rm.actor_count DESC;
