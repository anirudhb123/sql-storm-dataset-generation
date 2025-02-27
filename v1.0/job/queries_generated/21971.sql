WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS cast_rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        movie_id, title 
    FROM 
        RankedMovies 
    WHERE 
        cast_rank = 1
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ' ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    tm.title,
    tm.movie_id,
    COALESCE(mk.keywords, 'No Keywords') AS keywords,
    MAX(COi.status_id) AS highest_status,
    (SELECT COUNT(*) 
     FROM complete_cast cc 
     WHERE cc.movie_id = tm.movie_id) AS total_cast 
FROM 
    TopMovies tm
LEFT JOIN 
    movie_info mi ON tm.movie_id = mi.movie_id 
LEFT JOIN 
    movie_companies mco ON tm.movie_id = mco.movie_id 
LEFT JOIN 
    complete_cast COi ON tm.movie_id = COi.movie_id 
LEFT JOIN 
    MovieKeywords mk ON tm.movie_id = mk.movie_id
WHERE 
    (mi.info_type_id IS NULL OR mi.info LIKE '%incredible%') 
    AND (mco.note IS NULL OR mco.note NOT LIKE '%uncredited%')
GROUP BY 
    tm.title, tm.movie_id, mk.keywords
HAVING 
    MAX(COi.status_id) IS NOT NULL
ORDER BY 
    tm.production_year DESC, total_cast DESC
LIMIT 50;
