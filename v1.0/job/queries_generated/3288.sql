WITH RankedTitles AS (
    SELECT 
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
MovieActors AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        COUNT(DISTINCT c.person_id) OVER (PARTITION BY c.movie_id) AS actor_count
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
),
FilteredMovies AS (
    SELECT 
        m.movie_id,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count,
        COALESCE(MAX(CAST(LEFT(m.title, 1) AS CHAR)), 'N/A') AS first_character
    FROM 
        movie_keyword mk
    JOIN 
        aka_title m ON mk.movie_id = m.movie_id
    WHERE 
        m.production_year >= 2000
    GROUP BY 
        m.movie_id
)

SELECT 
    rt.title,
    rt.production_year,
    ma.actor_name,
    fm.keyword_count,
    fm.first_character
FROM 
    RankedTitles rt
JOIN 
    MovieActors ma ON rt.title = ma.movie_id
JOIN 
    FilteredMovies fm ON ma.movie_id = fm.movie_id
WHERE 
    rt.title_rank <= 5
ORDER BY 
    rt.production_year DESC, 
    fm.keyword_count DESC, 
    ma.actor_count ASC;
