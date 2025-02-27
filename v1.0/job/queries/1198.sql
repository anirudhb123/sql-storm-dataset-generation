WITH RankedMovies AS (
    SELECT 
        a.title,
        t.production_year,
        COUNT(distinct c.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(distinct c.person_id) DESC) AS popularity_rank
    FROM 
        aka_title a
    JOIN 
        title t ON a.movie_id = t.id
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        a.title, t.production_year
),
RecentMovies AS (
    SELECT 
        title,
        production_year,
        actor_count
    FROM 
        RankedMovies
    WHERE 
        production_year >= (SELECT MAX(production_year) - 5 FROM title)
),
FilteredMovies AS (
    SELECT 
        r.title,
        r.production_year,
        r.actor_count,
        CASE 
            WHEN r.actor_count > (SELECT AVG(actor_count) FROM RecentMovies) THEN 'Above Average'
            ELSE 'Below Average'
        END AS actor_performance
    FROM 
        RecentMovies r
)
SELECT 
    f.title,
    f.production_year,
    f.actor_count,
    f.actor_performance,
    COALESCE(m.note, 'No Note Available') AS movie_note
FROM 
    FilteredMovies f
LEFT JOIN 
    movie_info m ON f.title = m.info
WHERE 
    f.actor_performance = 'Above Average'
ORDER BY 
    f.production_year DESC, f.actor_count DESC;
