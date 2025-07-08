
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
        AND t.production_year >= 2000
),
Top10RatedMovies AS (
    SELECT 
        m.movie_id,
        COUNT(c.person_id) AS total_cast
    FROM 
        complete_cast m
    JOIN 
        cast_info c ON m.movie_id = c.movie_id
    GROUP BY 
        m.movie_id
    HAVING 
        COUNT(c.person_id) > 10
),
MoviesWithKeywords AS (
    SELECT 
        m.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        aka_title m ON mk.movie_id = m.id
    GROUP BY 
        m.movie_id
)
SELECT 
    R.title,
    R.production_year,
    COALESCE(ca.total_cast, 0) AS total_cast,
    COALESCE(k.keywords, 'No Keywords') AS keywords,
    CASE 
        WHEN R.year_rank <= 3 THEN 'Top Movie of the Year'
        ELSE 'Regular Movie'
    END AS movie_status
FROM 
    RankedMovies R
LEFT JOIN 
    Top10RatedMovies ca ON R.movie_id = ca.movie_id
LEFT JOIN 
    MoviesWithKeywords k ON R.movie_id = k.movie_id
WHERE 
    R.production_year = (SELECT MAX(production_year) FROM RankedMovies)
ORDER BY 
    R.title ASC;
