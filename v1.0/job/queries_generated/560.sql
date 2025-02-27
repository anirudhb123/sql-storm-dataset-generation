WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS rank
    FROM 
        aka_title t
    WHERE 
        t.production_year BETWEEN 2000 AND 2020
),
MovieCompanyCounts AS (
    SELECT 
        mc.movie_id,
        COUNT(*) AS company_count
    FROM 
        movie_companies mc
    GROUP BY 
        mc.movie_id
),
CastDetails AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON a.person_id = ci.person_id
    GROUP BY 
        ci.movie_id
)
SELECT 
    rt.title_id,
    rt.title,
    rt.production_year,
    COALESCE(cc.cast_count, 0) AS total_cast,
    COALESCE(cc.cast_names, 'No cast details') AS cast_details,
    COALESCE(mc.company_count, 0) AS production_companies,
    CASE 
        WHEN rt.rank <= 5 THEN 'Top 5 Titles'
        ELSE 'Other Titles'
    END AS title_rank_category
FROM 
    RankedTitles rt
LEFT JOIN 
    CastDetails cc ON rt.title_id = cc.movie_id
LEFT JOIN 
    MovieCompanyCounts mc ON rt.title_id = mc.movie_id
WHERE 
    rt.production_year IS NOT NULL
ORDER BY 
    rt.production_year DESC, rt.title;
