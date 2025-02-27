WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        title, 
        production_year 
    FROM 
        RankedMovies 
    WHERE 
        rank <= 5
),
MovieKeywords AS (
    SELECT 
        t.title,
        km.keyword
    FROM 
        TopMovies tm
    JOIN 
        movie_keyword mk ON tm.id = mk.movie_id
    JOIN 
        keyword km ON mk.keyword_id = km.id
)
SELECT 
    tm.title,
    tm.production_year,
    COALESCE(array_agg(DISTINCT mk.keyword) FILTER (WHERE mk.keyword IS NOT NULL), '{}') AS keywords,
    (SELECT 
        COUNT(*) 
     FROM 
        complete_cast cc 
     WHERE 
        cc.movie_id = tm.id) AS complete_cast_count
FROM 
    TopMovies tm
LEFT JOIN 
    MovieKeywords mk ON tm.title = mk.title
GROUP BY 
    tm.title, tm.production_year
ORDER BY 
    tm.production_year DESC, 
    tm.title;
