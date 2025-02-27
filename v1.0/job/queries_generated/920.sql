WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorCounts AS (
    SELECT 
        c.movie_id,
        COUNT(c.person_id) AS actor_count
    FROM 
        cast_info c
    GROUP BY 
        c.movie_id
),
TopMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        ac.actor_count
    FROM 
        RankedMovies rm
    LEFT JOIN 
        ActorCounts ac ON rm.movie_id = ac.movie_id
    WHERE 
        rm.year_rank <= 5
),
MovieDetails AS (
    SELECT 
        tm.movie_id,
        tm.title,
        tm.production_year,
        COALESCE(ac.n_order, 0) AS notable_actor_count
    FROM 
        TopMovies tm
    LEFT JOIN 
        (SELECT 
             movie_id,
             COUNT(DISTINCT person_id) AS n_order
         FROM 
             complete_cast
         WHERE 
             status_id = 1
         GROUP BY 
             movie_id) ac ON tm.movie_id = ac.movie_id
)
SELECT 
    md.title,
    md.production_year,
    md.actor_count,
    (SELECT 
         STRING_AGG(a.name, ', ') 
     FROM 
         aka_name a 
     JOIN 
         cast_info ci ON a.person_id = ci.person_id 
     WHERE 
         ci.movie_id = md.movie_id) AS actors,
    (SELECT 
         STRING_AGG(DISTINCT k.keyword, ', ')
     FROM 
         movie_keyword mk 
     JOIN 
         keyword k ON mk.keyword_id = k.id 
     WHERE 
         mk.movie_id = md.movie_id) AS keywords
FROM 
    MovieDetails md
ORDER BY 
    md.production_year DESC, 
    md.actor_count DESC;
