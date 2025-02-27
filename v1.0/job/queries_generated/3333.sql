WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rn
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    GROUP BY 
        a.id
),
TopMovies AS (
    SELECT 
        title,
        production_year
    FROM 
        RankedMovies
    WHERE 
        rn <= 5
),
MovieKeywords AS (
    SELECT 
        m.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword m
    JOIN 
        keyword k ON m.keyword_id = k.id
    GROUP BY 
        m.movie_id
)
SELECT 
    tm.title,
    tm.production_year,
    mk.keywords,
    COALESCE(NULLIF(mk.keywords, ''), 'No keywords') AS keyword_display,
    (SELECT COUNT(*) 
     FROM complete_cast cc 
     WHERE cc.movie_id = tm.id) AS complete_cast_count
FROM 
    TopMovies tm
LEFT JOIN 
    movie_info mi ON tm.title = mi.info
LEFT JOIN 
    MovieKeywords mk ON tm.movie_id = mk.movie_id
WHERE 
    (tm.production_year IS NOT NULL AND tm.production_year > 2000)
    OR (mi.info IS NOT NULL AND mi.note IS NOT NULL)
ORDER BY 
    tm.production_year DESC;
