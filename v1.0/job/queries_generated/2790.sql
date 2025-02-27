WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank_by_year
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorMovieCounts AS (
    SELECT 
        c.person_id,
        COUNT(DISTINCT c.movie_id) AS movie_count
    FROM 
        cast_info c
    GROUP BY 
        c.person_id
),
TopActors AS (
    SELECT 
        a.id AS actor_id,
        ak.name AS actor_name,
        ac.movie_count
    FROM 
        aka_name ak
    JOIN 
        ActorMovieCounts ac ON ak.person_id = ac.person_id
    WHERE 
        ac.movie_count > 5
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
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    ta.actor_name,
    mk.keywords
FROM 
    RankedMovies rm
LEFT JOIN 
    complete_cast cc ON rm.movie_id = cc.movie_id
LEFT JOIN 
    TopActors ta ON cc.subject_id = ta.actor_id
LEFT JOIN 
    MovieKeywords mk ON rm.movie_id = mk.movie_id
WHERE 
    rm.rank_by_year <= 5
ORDER BY 
    rm.production_year DESC, 
    rm.title;
