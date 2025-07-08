
WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        a.name AS actor_name,
        RANK() OVER (PARTITION BY t.production_year ORDER BY a.name) AS actor_rank
    FROM 
        aka_title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
),
TitleKeywords AS (
    SELECT 
        t.id AS title_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.id
)
SELECT 
    rt.title_id,
    rt.title,
    rt.production_year,
    rt.actor_name,
    rt.actor_rank,
    tk.keywords
FROM 
    RankedTitles rt
LEFT JOIN 
    TitleKeywords tk ON rt.title_id = tk.title_id
WHERE 
    rt.production_year >= 2000 AND 
    rt.actor_rank <= 3
ORDER BY 
    rt.production_year DESC, 
    rt.actor_rank ASC;
