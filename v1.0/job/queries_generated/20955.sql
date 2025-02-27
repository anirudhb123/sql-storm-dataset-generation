WITH RecursiveTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        c.name AS company_name,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS year_order,
        COUNT(*) OVER (PARTITION BY t.production_year) AS total_movies,
        CASE 
            WHEN COUNT(*) OVER (PARTITION BY t.production_year) > 5 THEN 'High Output' 
            ELSE 'Low Output' 
        END AS output_category
    FROM 
        aka_title t
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    WHERE 
        c.country_code IS NOT NULL
),

KeywordCount AS (
    SELECT 
        m.movie_id,
        COUNT(k.keyword) AS keyword_count
    FROM 
        movie_keyword m
    JOIN 
        keyword k ON m.keyword_id = k.id
    GROUP BY 
        m.movie_id
),

CastCounts AS (
    SELECT 
        ci.movie_id,
        COUNT(ci.person_id) AS actor_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),

CombinedData AS (
    SELECT 
        rt.title,
        rt.production_year,
        rt.company_name,
        rt.year_order,
        rt.total_movies,
        rt.output_category,
        kc.keyword_count,
        cc.actor_count
    FROM 
        RecursiveTitles rt
    LEFT JOIN 
        KeywordCount kc ON rt.title_id = kc.movie_id
    LEFT JOIN 
        CastCounts cc ON rt.title_id = cc.movie_id
)

SELECT 
    title,
    production_year,
    company_name,
    year_order,
    total_movies, 
    output_category,
    COALESCE(keyword_count, 0) AS keyword_count,
    COALESCE(actor_count, 0) AS actor_count,
    CASE 
        WHEN total_movies IS NULL THEN 'No Movies'
        WHEN total_movies > 10 THEN 'Blockbuster Year'
        ELSE 'Moderate Year'
    END AS year_category
FROM 
    CombinedData
WHERE 
    (keyword_count IS NULL OR keyword_count > 3)
    AND (actor_count IS NOT NULL OR TOTAL_COUNT IS NULL)
ORDER BY 
    production_year DESC, 
    year_order
LIMIT 50;
