WITH RankedMovies AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        COUNT(ci.person_id) AS total_cast,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank
    FROM 
        aka_title AS t
    JOIN 
        complete_cast AS cc ON t.id = cc.movie_id
    JOIN 
        cast_info AS ci ON cc.subject_id = ci.id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.title, t.production_year
),
TopMovies AS (
    SELECT 
        movie_title,
        production_year,
        total_cast
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
),
MovieKeywords AS (
    SELECT 
        t.title AS movie_title,
        k.keyword,
        COUNT(mk.id) AS keyword_count
    FROM 
        aka_title AS t
    JOIN 
        movie_keyword AS mk ON t.id = mk.movie_id
    JOIN 
        keyword AS k ON mk.keyword_id = k.id
    GROUP BY 
        t.title, k.keyword
),
KeywordStats AS (
    SELECT 
        movie_title,
        STRING_AGG(keyword, ', ') AS keywords
    FROM 
        MovieKeywords
    GROUP BY 
        movie_title
)
SELECT 
    tm.movie_title,
    tm.production_year,
    tm.total_cast,
    ks.keywords
FROM 
    TopMovies AS tm
LEFT JOIN 
    KeywordStats AS ks ON tm.movie_title = ks.movie_title
ORDER BY 
    tm.production_year DESC, tm.total_cast DESC;
