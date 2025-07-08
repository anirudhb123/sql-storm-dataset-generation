
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
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
HighestRankedMovies AS (
    SELECT 
        movie_id,
        title,
        production_year
    FROM 
        RankedMovies
    WHERE 
        rn = 1
),
MovieKeywords AS (
    SELECT 
        m.movie_id,
        LISTAGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword m
    JOIN 
        keyword k ON m.keyword_id = k.id
    GROUP BY 
        m.movie_id
)
SELECT 
    hm.movie_id,
    hm.title,
    hm.production_year,
    COALESCE(mk.keywords, 'No keywords') AS keywords,
    COUNT(DISTINCT ci.person_id) AS actor_count,
    (SELECT AVG(num) FROM (
        SELECT 
            COUNT(*) AS num 
        FROM 
            complete_cast cc
        GROUP BY 
            cc.movie_id
    ) AS avg_subquery) AS avg_cast_size
FROM 
    HighestRankedMovies hm
LEFT JOIN 
    cast_info ci ON hm.movie_id = ci.movie_id
LEFT JOIN 
    MovieKeywords mk ON hm.movie_id = mk.movie_id
GROUP BY 
    hm.movie_id, hm.title, hm.production_year, mk.keywords
HAVING 
    COUNT(DISTINCT ci.person_id) > (SELECT AVG(num) FROM (
        SELECT 
            COUNT(*) AS num 
        FROM 
            cast_info 
        GROUP BY 
            movie_id
    ) AS subquery) * 0.75
ORDER BY 
    hm.production_year DESC, actor_count DESC
LIMIT 10;
