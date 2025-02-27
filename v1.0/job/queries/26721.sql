
WITH RankedTitles AS (
    SELECT 
        at.title AS title,
        at.production_year AS year,
        ak.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY at.id ORDER BY ak.name) AS actor_rank
    FROM 
        aka_title at
    JOIN 
        cast_info ci ON at.id = ci.movie_id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        at.production_year BETWEEN 2000 AND 2020
),
KeywordStats AS (
    SELECT 
        mt.title AS title,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        aka_title mt ON mk.movie_id = mt.id
    GROUP BY 
        mt.title
),
TitleInfo AS (
    SELECT 
        at.title,
        at.production_year,
        COUNT(ci.id) AS cast_count,
        ki.keyword_count
    FROM 
        aka_title at
    LEFT JOIN 
        cast_info ci ON at.id = ci.movie_id
    LEFT JOIN 
        KeywordStats ki ON at.title = ki.title
    WHERE 
        at.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
    GROUP BY 
        at.title, at.production_year, ki.keyword_count
)
SELECT 
    ti.title,
    ti.production_year,
    ti.cast_count,
    COALESCE(ki.keyword_count, 0) AS keyword_count,
    STRING_AGG(DISTINCT rt.actor_name, ', ') AS actor_names
FROM 
    TitleInfo ti
LEFT JOIN 
    RankedTitles rt ON ti.title = rt.title AND rt.actor_rank <= 3
LEFT JOIN 
    KeywordStats ki ON ti.title = ki.title
GROUP BY 
    ti.title, ti.production_year, ti.cast_count, ki.keyword_count
ORDER BY 
    ti.production_year DESC, ti.title;
