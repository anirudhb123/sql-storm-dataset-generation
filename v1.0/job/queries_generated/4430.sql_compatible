
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(*) OVER (PARTITION BY t.id) AS cast_count,
        RANK() OVER (ORDER BY t.production_year DESC) AS year_rank
    FROM 
        aka_title t 
    WHERE 
        t.production_year IS NOT NULL
),
ActorInfo AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        a.person_id,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS actor_order
    FROM 
        cast_info c
    JOIN 
        aka_name a ON a.person_id = c.person_id
),
TopActors AS (
    SELECT 
        movie_id, 
        STRING_AGG(actor_name ORDER BY actor_order) AS actors
    FROM 
        ActorInfo
    GROUP BY 
        movie_id
),
MoviesWithKeywords AS (
    SELECT 
        m.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON k.id = mk.keyword_id
    JOIN 
        RankedMovies m ON m.movie_id = mk.movie_id
    GROUP BY 
        m.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    COALESCE(ta.actors, '') AS actors,
    COALESCE(mk.keywords, 'No keywords') AS keywords,
    rm.cast_count
FROM 
    RankedMovies rm
LEFT JOIN 
    TopActors ta ON rm.movie_id = ta.movie_id
LEFT JOIN 
    MoviesWithKeywords mk ON rm.movie_id = mk.movie_id
WHERE 
    rm.year_rank <= 10
ORDER BY 
    rm.production_year DESC, rm.title;
