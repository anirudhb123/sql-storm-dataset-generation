
WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
MovieDetails AS (
    SELECT 
        c.movie_id,
        STRING_AGG(DISTINCT ak.name || ' (' || r.role || ')', ', ') AS cast_names,
        COUNT(DISTINCT ak.id) AS actor_count
    FROM 
        cast_info c
    JOIN 
        aka_name ak ON ak.person_id = c.person_id
    JOIN 
        role_type r ON r.id = c.role_id
    GROUP BY 
        c.movie_id
),
KeywordDetails AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON k.id = mk.keyword_id
    GROUP BY 
        mk.movie_id
)
SELECT 
    rt.title,
    rt.production_year,
    md.cast_names,
    md.actor_count,
    kd.keywords
FROM 
    RankedTitles rt
LEFT JOIN 
    MovieDetails md ON md.movie_id = rt.title_id
LEFT JOIN 
    KeywordDetails kd ON kd.movie_id = rt.title_id
WHERE 
    rt.rank = 1
ORDER BY 
    rt.production_year DESC, 
    rt.title;
