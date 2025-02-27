WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(ci.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON cc.movie_id = t.id
    LEFT JOIN 
        cast_info ci ON ci.movie_id = cc.movie_id
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
KeywordCounts AS (
    SELECT 
        m.title, 
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = m.id
    WHERE 
        m.production_year >= 2000
    GROUP BY 
        m.id
)
SELECT 
    t.title AS Movie_Title,
    t.production_year AS Production_Year,
    COALESCE(kc.keyword_count, 0) AS Keyword_Count,
    COALESCE(rm.actor_count, 0) AS Actor_Count
FROM 
    TopMovies t
LEFT JOIN 
    KeywordCounts kc ON kc.title = t.title
LEFT JOIN 
    RankedMovies rm ON rm.title = t.title
WHERE 
    (rm.actor_count IS NULL OR rm.actor_count > 10)
ORDER BY 
    t.production_year DESC, 
    t.title;
