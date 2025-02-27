WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id, 
        t.title, 
        t.production_year, 
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) DESC) AS rank_by_cast_count
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
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
        rank_by_cast_count <= 5
),
MovieKeywords AS (
    SELECT 
        m.movie_id, 
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        TopMovies m
    LEFT JOIN 
        movie_keyword mk ON m.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.movie_id
)
SELECT 
    tm.title, 
    tm.production_year, 
    COALESCE(mk.keywords, 'No keywords found') AS keywords, 
    COUNT(DISTINCT ci.person_id) AS total_cast
FROM 
    TopMovies tm
LEFT JOIN 
    cast_info ci ON tm.movie_id = ci.movie_id
LEFT JOIN 
    MovieKeywords mk ON tm.movie_id = mk.movie_id
GROUP BY 
    tm.movie_id, tm.title, tm.production_year, mk.keywords
HAVING 
    COUNT(DISTINCT ci.person_id) > 0
ORDER BY 
    tm.production_year DESC, total_cast DESC;
