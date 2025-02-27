WITH RankedTitles AS (
    SELECT 
        t.title, 
        t.production_year, 
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rank
    FROM 
        title t
    WHERE 
        t.production_year >= 2000
),
CompanyCounts AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT c.id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    WHERE 
        c.country_code IS NOT NULL
    GROUP BY 
        mc.movie_id
),
CompleteCast AS (
    SELECT 
        c.movie_id, 
        COUNT(DISTINCT ci.person_id) AS total_cast
    FROM 
        complete_cast c
    LEFT JOIN 
        cast_info ci ON c.subject_id = ci.person_id
    GROUP BY 
        c.movie_id
)
SELECT 
    rt.title,
    rt.production_year,
    cc.company_count,
    cc.total_cast,
    CASE 
        WHEN cc.company_count IS NULL THEN 'No Companies'
        ELSE 'Companies Present'
    END AS company_status
FROM 
    RankedTitles rt
LEFT JOIN 
    (SELECT 
         cc.movie_id,
         c.company_count,
         cc.total_cast
     FROM 
         CompanyCounts c
     FULL OUTER JOIN 
         CompleteCast cc ON c.movie_id = cc.movie_id) AS cc ON rt.production_year = cc.movie_id
WHERE 
    rt.rank <= 5
ORDER BY 
    rt.production_year ASC;
