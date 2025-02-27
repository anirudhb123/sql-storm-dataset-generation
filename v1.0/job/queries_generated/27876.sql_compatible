
WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM 
        aka_title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        cast_info ci ON mc.movie_id = ci.movie_id
    GROUP BY 
        t.id, t.title, t.production_year, t.kind_id
), 
TitleKeywords AS (
    SELECT 
        t.id AS title_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.id
),
TopActors AS (
    SELECT 
        a.person_id,
        a.name,
        COUNT(ci.movie_id) AS movie_count
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    GROUP BY 
        a.person_id, a.name
    ORDER BY 
        movie_count DESC
    LIMIT 10
)
SELECT 
    rt.title,
    rt.production_year,
    rt.actor_count,
    tk.keywords,
    ta.name AS top_actor,
    ta.movie_count
FROM 
    RankedTitles rt
LEFT JOIN 
    TitleKeywords tk ON rt.title_id = tk.title_id
LEFT JOIN 
    TopActors ta ON rt.actor_count > 0 AND ta.movie_count > 5
WHERE 
    rt.production_year >= 2000
ORDER BY 
    rt.actor_count DESC, 
    rt.production_year ASC
LIMIT 50;
