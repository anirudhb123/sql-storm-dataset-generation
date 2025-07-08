
WITH RankedTitles AS (
    SELECT 
        a.name AS aka_name,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY LENGTH(t.title) DESC) AS title_rank
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        aka_title t ON ci.movie_id = t.movie_id
    WHERE 
        a.name IS NOT NULL
),
TitleSummary AS (
    SELECT 
        production_year,
        COUNT(*) AS title_count,
        AVG(LENGTH(movie_title)) AS avg_title_length,
        MAX(title_rank) AS max_rank
    FROM 
        RankedTitles
    GROUP BY 
        production_year
)
SELECT 
    ts.production_year,
    ts.title_count,
    ts.avg_title_length,
    ct.kind AS company_type,
    COUNT(DISTINCT mc.company_id) AS company_count
FROM 
    TitleSummary ts
JOIN 
    movie_companies mc ON ts.title_count > 0
JOIN 
    company_type ct ON mc.company_type_id = ct.id
WHERE 
    ts.production_year BETWEEN 2000 AND 2020
GROUP BY 
    ts.production_year, ts.title_count, ts.avg_title_length, ct.kind
ORDER BY 
    ts.production_year ASC, ts.avg_title_length DESC;
