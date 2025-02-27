
WITH RankedTitles AS (
    SELECT 
        a.id AS aka_id,
        a.name AS aka_name,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY t.production_year DESC) AS title_rank
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        aka_title t ON ci.movie_id = t.movie_id
    WHERE 
        t.production_year >= 2000
),

KeywordCounts AS (
    SELECT 
        m.movie_id,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        movie_info m ON mk.movie_id = m.movie_id
    GROUP BY 
        m.movie_id
)

SELECT 
    rt.aka_name,
    rt.movie_title,
    rt.production_year,
    kc.keyword_count,
    CASE 
        WHEN rt.title_rank = 1 THEN 'Primary Title'
        ELSE 'Secondary Title'
    END AS title_category
FROM 
    RankedTitles rt
LEFT JOIN 
    KeywordCounts kc ON rt.aka_id = kc.movie_id
WHERE 
    kc.keyword_count IS NOT NULL
ORDER BY 
    rt.production_year DESC, rt.aka_name;
