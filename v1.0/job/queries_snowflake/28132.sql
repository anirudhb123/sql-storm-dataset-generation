
WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        a.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY a.name) AS actor_rank
    FROM 
        aka_title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    WHERE 
        t.production_year >= 2000 
),

TitleKeywords AS (
    SELECT 
        mt.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        aka_title mt ON mk.movie_id = mt.id
    GROUP BY 
        mt.movie_id
),

TitleInfo AS (
    SELECT 
        ti.movie_id,
        LISTAGG(DISTINCT mi.info, '; ') WITHIN GROUP (ORDER BY mi.info) AS info_content
    FROM 
        movie_info mi
    JOIN 
        movie_info_idx ti ON mi.movie_id = ti.movie_id
    GROUP BY 
        ti.movie_id
)

SELECT 
    rt.title_id,
    rt.title,
    rt.production_year,
    rt.actor_name,
    tk.keywords,
    ti.info_content
FROM 
    RankedTitles rt
LEFT JOIN 
    TitleKeywords tk ON rt.title_id = tk.movie_id
LEFT JOIN 
    TitleInfo ti ON rt.title_id = ti.movie_id
WHERE 
    rt.actor_rank <= 3 
ORDER BY 
    rt.production_year DESC, rt.title;
