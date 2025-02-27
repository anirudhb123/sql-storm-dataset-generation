WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY t.title) AS year_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),

CompanyCounts AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        movie_companies mc
    GROUP BY 
        mc.movie_id
),

MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),

CastInformation AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS cast_size,
        MAX(ci.nr_order) AS highest_order
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
)

SELECT 
    t.title,
    t.production_year,
    rc.company_count,
    mk.keywords,
    ci.cast_size,
    ci.highest_order,
    CASE 
        WHEN ci.cast_size IS NULL THEN 'No Cast'
        WHEN ci.highest_order < 5 THEN 'Low Cast Order'
        WHEN rc.company_count = 0 THEN 'No Companies'
        ELSE 'Normal'
    END AS cast_company_status
FROM 
    RankedTitles t
LEFT JOIN 
    CompanyCounts rc ON t.title_id = rc.movie_id
LEFT JOIN 
    MovieKeywords mk ON t.title_id = mk.movie_id
LEFT JOIN 
    CastInformation ci ON t.title_id = ci.movie_id
WHERE 
    t.year_rank = 1 
    AND (rc.company_count IS NULL OR rc.company_count > 0)
    AND (ci.cast_size IS NOT NULL AND ci.cast_size > 2 OR ci.highest_order IS NULL)
ORDER BY 
    t.production_year DESC, 
    t.title;
