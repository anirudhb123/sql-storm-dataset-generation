WITH RankedTitles AS (
    SELECT 
        t.title AS movie_title, 
        t.production_year, 
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
),
ActorMovies AS (
    SELECT 
        a.name AS actor_name, 
        t.title AS movie_title, 
        COUNT(ci.movie_id) OVER (PARTITION BY a.id) AS movie_count
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        aka_title t ON ci.movie_id = t.id
    WHERE 
        a.name IS NOT NULL
),
FilteredResults AS (
    SELECT 
        rm.movie_title, 
        rm.production_year, 
        am.actor_name, 
        am.movie_count
    FROM 
        RankedTitles rm
    LEFT JOIN 
        ActorMovies am ON rm.movie_title = am.movie_title
    WHERE 
        rm.title_rank <= 5 AND (am.movie_count IS NULL OR am.movie_count > 1)
)
SELECT 
    fr.movie_title, 
    COALESCE(fr.actor_name, 'Unknown Actor') AS actor_name, 
    fr.production_year
FROM 
    FilteredResults fr
ORDER BY 
    fr.production_year DESC, 
    fr.movie_title;
