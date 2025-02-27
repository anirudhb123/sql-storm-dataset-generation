WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rn
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
CastDetails AS (
    SELECT 
        cc.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names
    FROM 
        complete_cast cc
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    GROUP BY 
        cc.movie_id
),
KeywordMovies AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    rt.title,
    rt.production_year,
    cd.total_cast,
    cd.cast_names,
    km.keywords,
    COALESCE(CASE WHEN rt.rn = 1 THEN 'First Title of Year' END, 'Not First') AS title_rank_status
FROM 
    RankedTitles rt
LEFT JOIN 
    CastDetails cd ON rt.title_id = cd.movie_id
LEFT JOIN 
    KeywordMovies km ON rt.title_id = km.movie_id
WHERE 
    (rt.production_year BETWEEN 2000 AND 2020) AND
    (rt.title ILIKE '%adventure%')
ORDER BY 
    rt.production_year DESC, 
    rt.title;
