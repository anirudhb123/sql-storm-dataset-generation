WITH RecursiveMovieCTE AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast
    FROM 
        aka_title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info c ON c.movie_id = t.id
    GROUP BY 
        t.title, t.production_year
),
KeywordCounts AS (
    SELECT 
        m.id AS movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    GROUP BY 
        m.id
)
SELECT 
    mm.movie_title,
    mm.production_year,
    COALESCE(kc.keyword_count, 0) AS total_keywords,
    mm.total_cast,
    RANK() OVER (ORDER BY mm.production_year DESC, mm.total_cast DESC) AS ranking
FROM 
    RecursiveMovieCTE mm
LEFT JOIN 
    KeywordCounts kc ON mm.production_year = kc.movie_id
WHERE 
    mm.total_cast > 5
    AND mm.production_year IS NOT NULL
    AND mm.production_year BETWEEN 2000 AND 2023
    OR (mm.movie_title LIKE '%Action%' OR mm.movie_title LIKE '%Comedy%')
ORDER BY 
    ranking
LIMIT 50;
