
WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        r.rank AS actor_rank
    FROM 
        title m
    LEFT JOIN 
        (SELECT 
            c.movie_id, 
            COUNT(*) AS actor_count,
            RANK() OVER (ORDER BY COUNT(*) DESC) AS rank
         FROM 
            cast_info c
         GROUP BY 
            c.movie_id) r ON m.id = r.movie_id
    WHERE 
        m.production_year >= 2000
),
ActorNames AS (
    SELECT 
        a.person_id, 
        LISTAGG(a.name, ', ') WITHIN GROUP (ORDER BY a.name) AS actor_names
    FROM 
        aka_name a
    GROUP BY 
        a.person_id
),
MovieKeywords AS (
    SELECT 
        mk.movie_id, 
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)

SELECT 
    rm.title,
    rm.production_year,
    COALESCE(an.actor_names, 'Unknown Actors') AS actors,
    COALESCE(mk.keywords, 'No Keywords') AS movie_keywords,
    rm.actor_rank
FROM 
    RankedMovies rm
LEFT JOIN 
    cast_info c ON rm.movie_id = c.movie_id
LEFT JOIN 
    ActorNames an ON c.person_id = an.person_id
LEFT JOIN 
    MovieKeywords mk ON rm.movie_id = mk.movie_id
WHERE 
    rm.actor_rank IS NOT NULL
ORDER BY 
    rm.actor_rank DESC, rm.production_year ASC;
