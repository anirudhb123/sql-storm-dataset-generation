WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    GROUP BY 
        a.title, a.production_year
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
        m.id AS movie_id,
        COUNT(DISTINCT k.keyword) AS keyword_count
    FROM 
        aka_title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        m.production_year >= 2000
    GROUP BY 
        m.id
)
SELECT 
    t.title,
    t.production_year,
    COALESCE(kc.keyword_count, 0) AS keyword_count,
    CASE 
        WHEN kc.keyword_count > 5 THEN 'High'
        WHEN kc.keyword_count BETWEEN 3 AND 5 THEN 'Medium'
        ELSE 'Low'
    END AS keyword_intensity
FROM 
    TopMovies t
LEFT JOIN 
    KeywordCounts kc ON t.title = (SELECT title FROM aka_title WHERE production_year = t.production_year LIMIT 1)
ORDER BY 
    t.production_year DESC, 
    keyword_count DESC;
