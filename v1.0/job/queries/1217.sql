WITH RankedTitles AS (
    SELECT 
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank,
        COUNT(DISTINCT c.person_id) AS cast_count
    FROM 
        aka_title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
CompanyStats AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT cn.country_code) AS unique_countries,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    rt.title,
    rt.production_year,
    rt.cast_count,
    cs.unique_countries,
    cs.company_names
FROM 
    RankedTitles rt
LEFT JOIN 
    CompanyStats cs ON rt.title_rank <= 5 AND rt.production_year = cs.movie_id
WHERE 
    rt.cast_count > 0 
    AND rt.production_year IS NOT NULL
ORDER BY 
    rt.production_year DESC, 
    rt.title;
