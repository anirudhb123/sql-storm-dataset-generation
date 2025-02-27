WITH RankedTitles AS (
    SELECT 
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY a.name) AS title_rank
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        aka_title t ON ci.movie_id = t.movie_id
),
KeywordAnalysis AS (
    SELECT 
        t.id AS title_id,
        k.keyword,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.id, k.keyword
),
InfoSummary AS (
    SELECT 
        m.id AS movie_id,
        STRING_AGG(DISTINCT mt.info || ': ' || mt.note, '; ') AS movie_info
    FROM 
        movie_info m
    JOIN 
        info_type it ON m.info_type_id = it.id
    GROUP BY 
        m.id
)

SELECT 
    rt.actor_name,
    rt.movie_title,
    rt.production_year,
    ka.keyword,
    ka.keyword_count,
    is.movie_info
FROM 
    RankedTitles rt
JOIN 
    KeywordAnalysis ka ON rt.title_rank = ka.title_id
JOIN 
    InfoSummary is ON rt.movie_title = is.movie_id
WHERE 
    rt.title_rank = 1
ORDER BY 
    rt.production_year DESC, rt.actor_name;
