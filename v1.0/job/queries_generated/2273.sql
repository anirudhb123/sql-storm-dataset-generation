WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank,
        COUNT(mk.movie_id) AS keyword_count
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.keyword_count
    FROM 
        RankedMovies rm
    WHERE 
        rm.title_rank = 1 AND rm.keyword_count > 5
),
ActorCount AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM 
        cast_info c
    JOIN 
        top_movies tm ON c.movie_id = tm.movie_id
    GROUP BY 
        c.movie_id
)
SELECT 
    tm.title,
    tm.production_year,
    ac.actor_count,
    COALESCE(NULLIF(ac.actor_count, 0), 'No actors') AS actor_count_display,
    CASE 
        WHEN ac.actor_count IS NULL THEN 'Unknown'
        ELSE 'Known'
    END AS count_status
FROM 
    TopMovies tm
LEFT JOIN 
    ActorCount ac ON tm.movie_id = ac.movie_id
ORDER BY 
    tm.production_year DESC, tm.title;
