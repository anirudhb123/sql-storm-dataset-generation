WITH RankedTitles AS (
    SELECT 
        at.title AS movie_title,
        at.production_year,
        ak.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY at.id ORDER BY ak.name) AS actor_rank
    FROM 
        aka_title at
    JOIN 
        cast_info ci ON at.id = ci.movie_id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        at.production_year BETWEEN 2000 AND 2023
),
FilteredTitles AS (
    SELECT 
        rt.movie_title,
        rt.production_year,
        COUNT(rt.actor_name) AS actor_count
    FROM 
        RankedTitles rt
    GROUP BY 
        rt.movie_title, rt.production_year
    HAVING 
        COUNT(rt.actor_name) > 5
),
KeywordCount AS (
    SELECT 
        mt.title,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        movie_info mi ON mk.movie_id = mi.movie_id
    JOIN 
        title mt ON mk.movie_id = mt.id
    GROUP BY 
        mt.title
)
SELECT 
    ft.movie_title,
    ft.production_year,
    ft.actor_count,
    kc.keyword_count
FROM 
    FilteredTitles ft
LEFT JOIN 
    KeywordCount kc ON ft.movie_title = kc.title
ORDER BY 
    ft.production_year DESC, ft.actor_count DESC;
