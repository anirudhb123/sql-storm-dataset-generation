WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rn
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        title,
        production_year,
        total_cast
    FROM 
        RankedMovies
    WHERE 
        rn <= 10
),
MovieKeywords AS (
    SELECT 
        m.id AS movie_id,
        k.keyword
    FROM 
        aka_title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        m.production_year >= 2000
),
KeywordCounts AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(mk.keyword, ', ') AS keywords_list,
        COUNT(mk.keyword) AS keyword_count
    FROM 
        MovieKeywords mk
    GROUP BY 
        mk.movie_id
)
SELECT 
    tm.title,
    tm.production_year,
    COALESCE(kc.keywords_list, 'No Keywords') AS keywords,
    tm.total_cast,
    COALESCE(kc.keyword_count, 0) AS keyword_count
FROM 
    TopMovies tm
LEFT JOIN 
    KeywordCounts kc ON tm.title = (SELECT title FROM aka_title WHERE id = kc.movie_id)
ORDER BY 
    tm.production_year DESC, 
    tm.total_cast DESC;
