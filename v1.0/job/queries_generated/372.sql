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
CastCount AS (
    SELECT 
        ci.movie_id,
        COUNT(ci.person_id) AS total_cast
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),
MoviesWithCast AS (
    SELECT 
        rt.title,
        rt.production_year,
        cc.total_cast
    FROM 
        RankedTitles rt
    JOIN 
        CastCount cc ON rt.id = cc.movie_id
)
SELECT 
    mwc.title,
    mwc.production_year,
    mwc.total_cast,
    COALESCE(CAST(SUM(CASE WHEN mwc.total_cast > 5 THEN 1 ELSE 0 END) AS INTEGER), 0) AS high_cast_count,
    COALESCE(AVG(CASE WHEN mwc.production_year IS NOT NULL THEN mwc.total_cast END) OVER(), 0) AS avg_cast_per_year
FROM 
    MoviesWithCast mwc
LEFT JOIN 
    movie_info mi ON mwc.production_year = mi.movie_id
WHERE 
    mwc.total_cast IS NOT NULL
    AND mwc.production_year > 2000
GROUP BY 
    mwc.title, mwc.production_year, mwc.total_cast
ORDER BY 
    mwc.production_year DESC, mwc.title ASC;
