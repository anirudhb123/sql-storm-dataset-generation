WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ak.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY ak.name) AS actor_rank
    FROM 
        aka_title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    JOIN 
        aka_name ak ON c.person_id = ak.person_id
    WHERE 
        t.production_year >= 2000
),
MovieDetails AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        STRING_AGG(rm.actor_name, ', ') AS actors
    FROM 
        RankedMovies rm
    GROUP BY 
        rm.movie_id, rm.title, rm.production_year
),
KeywordInfo AS (
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
    md.title,
    md.production_year,
    md.actors,
    ki.keywords
FROM 
    MovieDetails md
LEFT JOIN 
    KeywordInfo ki ON md.movie_id = ki.movie_id
WHERE 
    md.production_year = (
        SELECT MAX(production_year) 
        FROM MovieDetails
    )
ORDER BY 
    md.title ASC;
