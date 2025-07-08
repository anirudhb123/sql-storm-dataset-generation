
WITH RankedMovies AS (
    SELECT 
        at.id AS movie_id,
        at.title AS movie_title,
        at.production_year,
        COUNT(ci.id) AS actor_count,
        ARRAY_AGG(DISTINCT ak.name) AS actor_names,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(ci.id) DESC) AS rank
    FROM 
        aka_title at
    LEFT JOIN 
        cast_info ci ON at.id = ci.movie_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        at.production_year >= 2000
    GROUP BY 
        at.id, at.title, at.production_year
), MovieKeywords AS (
    SELECT 
        mk.movie_id,
        LISTAGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
), TopActors AS (
    SELECT 
        ai.movie_id,
        LISTAGG(DISTINCT a.name, ', ') AS top_actors
    FROM 
        complete_cast ai
    JOIN 
        aka_name a ON ai.subject_id = a.id
    GROUP BY 
        ai.movie_id
)
SELECT 
    rm.movie_title,
    rm.production_year,
    rm.actor_count,
    rm.actor_names,
    COALESCE(mk.keywords, 'No keywords found') AS keywords,
    COALESCE(ta.top_actors, 'No actors found') AS top_actors
FROM 
    RankedMovies rm
LEFT JOIN 
    MovieKeywords mk ON rm.movie_id = mk.movie_id
LEFT JOIN 
    TopActors ta ON rm.movie_id = ta.movie_id
WHERE 
    rm.rank <= 5
ORDER BY 
    rm.production_year DESC, rm.actor_count DESC;
