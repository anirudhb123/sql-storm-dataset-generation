WITH RankedTitles AS (
    SELECT 
        t.title,
        t.production_year,
        t.id AS title_id,
        COUNT(c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, t.title) AS ranking
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.title, t.production_year, t.id
),
TopRankedTitles AS (
    SELECT 
        title, 
        production_year 
    FROM 
        RankedTitles 
    WHERE 
        ranking <= 10
),
CompanyCounts AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT cn.id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    tr.title,
    tr.production_year,
    cc.company_count,
    CASE 
        WHEN cc.company_count IS NULL THEN 'No Companies'
        WHEN cc.company_count > 5 THEN 'Many Companies'
        ELSE 'Few Companies'
    END AS company_status
FROM 
    TopRankedTitles tr
LEFT JOIN 
    CompanyCounts cc ON tr.title_id = cc.movie_id
WHERE 
    tr.production_year >= 2000
ORDER BY 
    tr.production_year DESC, 
    tr.title;
