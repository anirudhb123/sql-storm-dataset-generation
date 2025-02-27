WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank,
        COUNT(CASE WHEN ci.role_id IS NOT NULL THEN 1 END) OVER (PARTITION BY t.id) AS cast_count
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    WHERE 
        t.production_year IS NOT NULL
), 
GroupedCompanies AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
        COUNT(DISTINCT mc.company_id) AS unique_company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
), 
KeywordCounts AS (
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
)
SELECT 
    rt.title_id,
    rt.title,
    rt.production_year,
    rt.title_rank,
    COALESCE(gc.company_names, 'No Companies') AS company_names,
    COALESCE(kc.keyword_count, 0) AS keyword_count,
    rt.cast_count
FROM 
    RankedTitles rt
LEFT JOIN 
    GroupedCompanies gc ON rt.title_id = gc.movie_id
LEFT JOIN 
    KeywordCounts kc ON rt.title_id = kc.movie_id
WHERE 
    rt.cast_count > 0
AND 
    rt.title_rank = 1
ORDER BY 
    rt.production_year DESC,
    rt.title ASC
LIMIT 50;

-- An additional bizarre semantic application
SELECT 
    rt.title_id,
    rt.title,
    COALESCE(NULLIF(rt.production_year, 0), 'Unknown Year') AS production_year_alias,
    CASE 
        WHEN rt.cast_count IS NULL THEN 'No Cast'
        WHEN rt.cast_count > 5 THEN 'Ensemble Cast'
        ELSE 'Minimal Cast'
    END AS cast_category
FROM 
    RankedTitles rt
WHERE 
    rt.cast_count IS NOT NULL OR rt.title_rank IS NULL
OR 
    rt.production_year IN (SELECT DISTINCT production_year 
                           FROM movie_info mi 
                           WHERE mi.info LIKE '%award%')
ORDER BY 
    cast_category DESC;

