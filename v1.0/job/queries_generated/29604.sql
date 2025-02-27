WITH RankedTitles AS (
    SELECT 
        at.id AS title_id,
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.title) AS title_rank
    FROM 
        aka_title at
    WHERE 
        at.production_year IS NOT NULL
),
MovieActors AS (
    SELECT 
        c.movie_id,
        coalesce(a.name, 'Unknown Actor') AS actor_name,
        COUNT(*) AS appearance_count
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        c.movie_id, a.name
),
TopMovies AS (
    SELECT 
        ma.movie_id,
        ma.actor_name,
        ma.appearance_count,
        rt.title,
        rt.title_rank
    FROM 
        MovieActors ma
    JOIN 
        RankedTitles rt ON ma.movie_id = rt.title_id
    WHERE 
        ma.appearance_count > 3
    ORDER BY 
        rt.production_year DESC,
        ma.appearance_count DESC
    LIMIT 10
)
SELECT 
    tm.title,
    tm.actor_name,
    tm.appearance_count,
    rt.production_year
FROM 
    TopMovies tm
JOIN 
    RankedTitles rt ON tm.movie_id = rt.title_id
WHERE 
    rt.title_rank <= 5
ORDER BY 
    rt.production_year DESC,
    tm.appearance_count DESC;

This query leverages common table expressions (CTEs) to rank movie titles by the year of production, counts actor appearances in each movie, and filters to return the top movies featuring actors with multiple appearances. The final selection focuses on the top-ranked titles from the most recent years, giving a comprehensive view of prolific actors in notable films.
