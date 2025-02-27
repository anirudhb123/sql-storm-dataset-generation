WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
CastDetails AS (
    SELECT 
        ci.movie_id,
        STRING_AGG(DISTINCT ak.name, ', ') AS actor_names,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        ci.movie_id
)
SELECT 
    rt.title_id,
    rt.title,
    rt.production_year,
    COALESCE(mk.keywords, 'No Keywords') AS keywords,
    COALESCE(cd.actor_names, 'No Cast') AS actor_names,
    cd.actor_count,
    CASE 
        WHEN cd.actor_count > 5 THEN 'Large Cast'
        WHEN cd.actor_count BETWEEN 3 AND 5 THEN 'Medium Cast'
        ELSE 'Small Cast'
    END AS cast_size
FROM 
    RankedTitles rt
LEFT JOIN 
    MovieKeywords mk ON rt.title_id = mk.movie_id
LEFT JOIN 
    CastDetails cd ON rt.title_id = cd.movie_id
WHERE 
    rt.title_rank = 1
ORDER BY 
    rt.production_year DESC, rt.title;
