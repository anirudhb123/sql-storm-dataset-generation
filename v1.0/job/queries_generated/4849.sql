WITH RankedTitles AS (
    SELECT 
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.title) AS title_rank
    FROM 
        aka_title at
    WHERE 
        at.production_year IS NOT NULL
),
CastDetails AS (
    SELECT 
        ci.movie_id,
        COUNT(*) AS cast_count,
        STRING_AGG(DISTINCT an.name, ', ') AS actor_names
    FROM 
        cast_info ci
    JOIN 
        aka_name an ON ci.person_id = an.person_id
    GROUP BY 
        ci.movie_id
),
MovieInfo AS (
    SELECT 
        m.id AS movie_id,
        COALESCE(mi.info, 'No info available') AS movie_info,
        mt.kind AS company_type
    FROM 
        movie_companies m
    LEFT JOIN 
        movie_info mi ON m.movie_id = mi.movie_id
    LEFT JOIN 
        company_type mt ON m.company_type_id = mt.id
)
SELECT 
    rt.title,
    rt.production_year,
    cd.cast_count,
    cd.actor_names,
    mi.movie_info,
    mi.company_type,
    COUNT(DISTINCT mk.keyword) AS keyword_count
FROM 
    RankedTitles rt
LEFT JOIN 
    CastDetails cd ON rt.title = cd.movie_id
LEFT JOIN 
    MovieInfo mi ON rt.id = mi.movie_id
LEFT JOIN 
    movie_keyword mk ON rt.id = mk.movie_id
WHERE 
    rt.title_rank <= 5
GROUP BY 
    rt.title, rt.production_year, cd.cast_count, cd.actor_names, mi.movie_info, mi.company_type
ORDER BY 
    rt.production_year DESC, cd.cast_count DESC;
