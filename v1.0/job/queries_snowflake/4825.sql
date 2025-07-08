
WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS title_rank
    FROM 
        aka_title t
    WHERE
        t.production_year IS NOT NULL
),
ActorTitles AS (
    SELECT 
        a.person_id,
        a.name AS actor_name,
        r.title_id,
        r.title,
        r.production_year,
        r.title_rank
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        RankedTitles r ON c.movie_id = r.title_id
),
TitleKeywords AS (
    SELECT 
        m.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword m 
    JOIN 
        keyword k ON m.keyword_id = k.id
    GROUP BY 
        m.movie_id
)
SELECT 
    at.actor_name,
    COUNT(DISTINCT at.title_id) AS total_titles,
    LISTAGG(DISTINCT tk.keywords, '; ') WITHIN GROUP (ORDER BY tk.keywords) AS all_keywords,
    MAX(at.production_year) AS latest_year,
    AVG(NULLIF(at.title_rank, 0)) AS avg_rank
FROM 
    ActorTitles at
LEFT JOIN 
    TitleKeywords tk ON at.title_id = tk.movie_id
GROUP BY 
    at.actor_name
HAVING 
    COUNT(DISTINCT at.title_id) > 5 
    AND AVG(NULLIF(at.title_rank, 0)) < 3
ORDER BY 
    total_titles DESC;
