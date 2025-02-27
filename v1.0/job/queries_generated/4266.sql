WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rank,
        COUNT(DISTINCT ci.person_id) OVER (PARTITION BY t.id) AS cast_count
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    WHERE 
        t.production_year IS NOT NULL
),
TopMovies AS (
    SELECT 
        *,
        CASE 
            WHEN cast_count > 10 THEN 'Ensemble'
            WHEN cast_count BETWEEN 5 AND 10 THEN 'Regular'
            ELSE 'Minimal'
        END AS cast_size
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
)

SELECT 
    tm.movie_id,
    tm.title,
    tm.production_year,
    tm.cast_size,
    COUNT(DISTINCT kw.keyword) AS keyword_count,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
    COALESCE(cn.name, 'Unknown Company') AS production_company
FROM 
    TopMovies tm
LEFT JOIN 
    movie_keyword mk ON tm.movie_id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
LEFT JOIN 
    movie_companies mc ON tm.movie_id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
GROUP BY 
    tm.movie_id, tm.title, tm.production_year, tm.cast_size, cn.name
HAVING 
    COUNT(DISTINCT kw.keyword) > 0
ORDER BY 
    tm.production_year DESC, keyword_count DESC;
