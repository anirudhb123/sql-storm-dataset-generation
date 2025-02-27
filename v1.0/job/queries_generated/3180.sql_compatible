
WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rn
    FROM 
        title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.person_id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        title_id, title, production_year
    FROM 
        RankedMovies
    WHERE 
        rn <= 5
),
KeywordCounts AS (
    SELECT 
        mi.movie_id,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    INNER JOIN 
        movie_info mi ON mk.movie_id = mi.movie_id
    GROUP BY 
        mi.movie_id
)
SELECT 
    tm.title,
    tm.production_year,
    COALESCE(kc.keyword_count, 0) AS keyword_count,
    COALESCE(ak.name, 'Unknown') AS actor_name
FROM 
    TopMovies tm
LEFT JOIN 
    KeywordCounts kc ON tm.title_id = kc.movie_id
LEFT JOIN 
    complete_cast cc ON tm.title_id = cc.movie_id
LEFT JOIN 
    aka_name ak ON cc.subject_id = ak.person_id
WHERE 
    tm.production_year >= 2000
ORDER BY 
    tm.production_year DESC, 
    keyword_count DESC, 
    tm.title;
