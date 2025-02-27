
WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        kt.kind AS kind,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY LENGTH(t.title) DESC) AS title_rank
    FROM 
        title t
    JOIN 
        kind_type kt ON t.kind_id = kt.id
    WHERE 
        t.production_year >= 2000
),
CastDetails AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        STRING_AGG(DISTINCT ak.name, ', ') AS cast_names
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        ci.movie_id
),
KeywordDetails AS (
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
    rt.title_id,
    rt.title,
    rt.production_year,
    rt.kind,
    COALESCE(cd.total_cast, 0) AS total_cast,
    COALESCE(cd.cast_names, '') AS cast_names,
    COALESCE(kd.keywords, '') AS keywords
FROM 
    RankedTitles rt
LEFT JOIN 
    CastDetails cd ON rt.title_id = cd.movie_id
LEFT JOIN 
    KeywordDetails kd ON rt.title_id = kd.movie_id
WHERE 
    rt.title_rank <= 5
ORDER BY 
    rt.production_year DESC, 
    rt.title_rank;
