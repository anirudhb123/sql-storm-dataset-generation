WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) AS rn
    FROM 
        aka_title a
    WHERE 
        a.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
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
TopActors AS (
    SELECT 
        c.movie_id,
        ak.name,
        COUNT(c.person_id) AS actor_count
    FROM 
        cast_info c
    JOIN 
        aka_name ak ON c.person_id = ak.person_id
    GROUP BY 
        c.movie_id, ak.name
    HAVING 
        COUNT(c.person_id) > 1
)
SELECT 
    rm.title,
    rm.production_year,
    COALESCE(mk.keywords, 'No keywords') AS keywords,
    COALESCE(ta.name, 'Unknown') AS top_actor,
    ta.actor_count
FROM 
    RankedMovies rm
LEFT JOIN 
    MovieKeywords mk ON rm.id = mk.movie_id
LEFT JOIN 
    TopActors ta ON rm.id = ta.movie_id
WHERE 
    rm.rn <= 10
ORDER BY 
    rm.production_year DESC, ta.actor_count DESC;
