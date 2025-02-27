WITH RankedTitles AS (
    SELECT 
        a.name AS actor_name,
        t.title AS movie_title,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY t.production_year DESC) as rank,
        t.production_year
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        aka_title t ON ci.movie_id = t.movie_id
),
TitleKeywords AS (
    SELECT 
        t.id as title_id,
        k.keyword
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id 
    WHERE 
        k.keyword IS NOT NULL
)
SELECT 
    rt.actor_name,
    rt.movie_title,
    rt.production_year,
    COUNT(tk.keyword) AS keyword_count,
    CASE 
        WHEN rt.rank = 1 THEN 'Latest Movie'
        ELSE 'Earlier Movie'
    END as movie_status
FROM 
    RankedTitles rt
LEFT JOIN 
    TitleKeywords tk ON rt.movie_title = tk.title_id
WHERE 
    rt.production_year >= 2000
GROUP BY 
    rt.actor_name, rt.movie_title, rt.production_year, rt.rank
HAVING 
    COUNT(tk.keyword) > 1
ORDER BY 
    rt.actor_name, rt.production_year DESC;
