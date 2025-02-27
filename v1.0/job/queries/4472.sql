WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
),
MovieDetails AS (
    SELECT 
        tm.title,
        tm.production_year,
        STRING_AGG(DISTINCT an.name, ', ') AS actors,
        COALESCE(SUM(mk.id), 0) AS keyword_count
    FROM 
        TopMovies tm
    LEFT JOIN 
        cast_info ci ON tm.movie_id = ci.movie_id
    LEFT JOIN 
        aka_name an ON ci.person_id = an.person_id
    LEFT JOIN 
        movie_keyword mk ON tm.movie_id = mk.movie_id
    GROUP BY 
        tm.movie_id, tm.title, tm.production_year
),
NullCheck AS (
    SELECT 
        title,
        production_year,
        actors,
        CASE WHEN keyword_count IS NULL THEN 'No Keywords' ELSE 'Has Keywords' END AS keyword_status
    FROM 
        MovieDetails
)
SELECT 
    title,
    production_year,
    actors,
    keyword_status
FROM 
    NullCheck
WHERE 
    production_year >= 2000
ORDER BY 
    production_year DESC, title;
