WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS year_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
MoviesWithGenres AS (
    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        STRING_AGG(DISTINCT g.keyword, ', ') AS genres
    FROM 
        RankedMovies m
    LEFT JOIN 
        movie_keyword mk ON m.movie_id = mk.movie_id
    LEFT JOIN 
        keyword g ON mk.keyword_id = g.id
    GROUP BY 
        m.movie_id, m.title, m.production_year
),
MovieCastInfo AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS total_cast,
        SUM(CASE WHEN r.role = 'Director' THEN 1 ELSE 0 END) AS director_count
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.movie_id
)
SELECT 
    mw.movie_id,
    mw.title,
    mw.production_year,
    mw.genres,
    COALESCE(ci.total_cast, 0) AS total_cast,
    COALESCE(ci.director_count, 0) AS director_count,
    CASE 
        WHEN mw.production_year IS NOT NULL AND mw.genres IS NOT NULL THEN 'Valid Movie'
        WHEN mw.production_year IS NULL AND mw.genres IS NULL THEN 'Unknown'
        ELSE 'Incomplete Data'
    END AS movie_status
FROM 
    MoviesWithGenres mw
LEFT JOIN 
    MovieCastInfo ci ON mw.movie_id = ci.movie_id
WHERE 
    mw.production_year BETWEEN 2000 AND 2023
ORDER BY 
    mw.production_year DESC, mw.title ASC;
