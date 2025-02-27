WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        AVG(CASE WHEN c.note IS NOT NULL THEN 1 ELSE 0 END) OVER (PARTITION BY a.id) AS has_notes_avg,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    GROUP BY 
        a.id, a.title, a.production_year
),
TopMovies AS (
    SELECT 
        title, 
        production_year, 
        actor_count
    FROM 
        RankedMovies
    WHERE 
        rank <= 10
),
MoviesWithInfo AS (
    SELECT 
        tm.title,
        tm.production_year,
        ti.info AS movie_info
    FROM 
        TopMovies tm
    LEFT JOIN 
        movie_info ti ON tm.production_year = ti.movie_id 
    WHERE 
        ti.note IS NULL OR ti.note <> 'N/A'
)
SELECT 
    mw.title,
    mw.production_year,
    COALESCE(mw.movie_info, 'No Info Available') AS movie_info,
    mt.kind AS movie_kind,
    cnt.actor_count
FROM 
    MoviesWithInfo mw
LEFT JOIN 
    aka_title at ON mw.title = at.title
LEFT JOIN 
    kind_type mt ON at.kind_id = mt.id
LEFT JOIN 
    (SELECT 
         movie_id, 
         COUNT(person_id) AS actor_count 
     FROM 
         cast_info 
     GROUP BY 
         movie_id) cnt ON at.id = cnt.movie_id
WHERE 
    mw.production_year >= 2000
ORDER BY 
    mw.production_year DESC, 
    cnt.actor_count DESC;
