WITH RankedTitles AS (
    SELECT 
        t.id AS title_id, 
        t.title,
        a.name AS actor_name,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        a.name IS NOT NULL
),
KeywordsPerTitle AS (
    SELECT 
        m.movie_id, 
        COUNT(k.id) AS keyword_count
    FROM 
        movie_keyword m
    JOIN 
        keyword k ON m.keyword_id = k.id
    GROUP BY 
        m.movie_id
),
MoviesWithKeywords AS (
    SELECT 
        rt.*,
        kpt.keyword_count
    FROM 
        RankedTitles rt
    LEFT JOIN 
        KeywordsPerTitle kpt ON rt.title_id = kpt.movie_id
)

SELECT 
    production_year, 
    COUNT(DISTINCT title_id) AS total_titles,
    SUM(keyword_count) AS total_keywords,
    AVG(keyword_count) AS avg_keywords_per_title
FROM 
    MoviesWithKeywords
WHERE 
    production_year >= 2000
GROUP BY 
    production_year
ORDER BY 
    production_year DESC;
