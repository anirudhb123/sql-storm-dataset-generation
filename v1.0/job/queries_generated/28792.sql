WITH RankedTitles AS (
    SELECT 
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY LENGTH(t.title) DESC) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorCounts AS (
    SELECT 
        c.movie_id, 
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM 
        cast_info c
    GROUP BY 
        c.movie_id
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
TopMovies AS (
    SELECT 
        rt.title,
        rt.production_year,
        ac.actor_count,
        mk.keywords
    FROM 
        RankedTitles rt
    JOIN 
        ActorCounts ac ON rt.title = ac.movie_id
    JOIN 
        MovieKeywords mk ON ac.movie_id = mk.movie_id
    WHERE 
        rt.title_rank <= 10
)
SELECT 
    tm.title,
    tm.production_year,
    tm.actor_count,
    tm.keywords
FROM 
    TopMovies tm
ORDER BY 
    tm.production_year DESC, 
    tm.actor_count DESC;
