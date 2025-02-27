WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
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
        ci.movie_id,
        ak.name AS actor_name,
        RANK() OVER (PARTITION BY ci.movie_id ORDER BY COUNT(*) DESC) AS actor_rank
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        ci.movie_id, ak.name
    HAVING 
        COUNT(*) > 1
),
MoviesWithCompanionData AS (
    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        COALESCE(kw.keywords, 'No Keywords') AS keywords,
        COALESCE(a.actor_name, 'No Actor') AS top_actor
    FROM 
        RankedMovies m
    LEFT JOIN 
        MovieKeywords kw ON m.movie_id = kw.movie_id
    LEFT JOIN 
        (SELECT movie_id, actor_name FROM TopActors WHERE actor_rank = 1) a ON m.movie_id = a.movie_id
)
SELECT 
    mw.title,
    mw.production_year,
    mw.keywords,
    mw.top_actor
FROM 
    MoviesWithCompanionData mw
WHERE 
    mw.production_year >= 2000 
    AND mw.top_actor IS NOT NULL
ORDER BY 
    mw.production_year DESC, mw.title;
