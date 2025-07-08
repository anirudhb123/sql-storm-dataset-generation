WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year >= 2000
),

AkaNames AS (
    SELECT 
        a.id AS aka_id,
        a.name,
        a.person_id
    FROM 
        aka_name a 
    WHERE 
        a.name ILIKE 'John%'
),

CompleteCast AS (
    SELECT 
        cc.movie_id,
        COUNT(DISTINCT cc.person_id) AS cast_count
    FROM 
        cast_info cc
    GROUP BY 
        cc.movie_id
)

SELECT 
    rt.title,
    rt.production_year,
    ak.name AS actor_name,
    cc.cast_count
FROM 
    RankedTitles rt 
JOIN 
    cast_info ci ON rt.title_id = ci.movie_id
JOIN 
    AkaNames ak ON ci.person_id = ak.person_id
JOIN 
    CompleteCast cc ON cc.movie_id = rt.title_id
WHERE 
    rt.title_rank <= 5
ORDER BY 
    rt.production_year DESC, 
    rt.title;
