
WITH RECURSIVE TitleHierarchy AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id,
        COALESCE(SUM(CASE WHEN c.id IS NOT NULL THEN 1 ELSE 0 END), 0) AS total_cast,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, t.title) AS year_rank
    FROM 
        title t
    LEFT JOIN 
        aka_title at ON t.id = at.movie_id
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year, t.kind_id
),
FilteredTitles AS (
    SELECT 
        th.title_id,
        th.title,
        th.production_year,
        th.total_cast,
        th.year_rank,
        CASE 
            WHEN th.year_rank = 1 THEN 'Latest'
            ELSE 'Older'
        END AS title_category
    FROM 
        TitleHierarchy th
    WHERE 
        th.production_year IS NOT NULL
),
CompanyAggregates AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT cn.id) AS company_count,
        STRING_AGG(cn.name, ', ') AS company_names
    FROM 
        movie_companies mc
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
FinalResults AS (
    SELECT 
        ft.title,
        ft.production_year,
        ft.total_cast,
        ca.company_count,
        ca.company_names
    FROM 
        FilteredTitles ft
    LEFT JOIN 
        CompanyAggregates ca ON ft.title_id = ca.movie_id
)
SELECT 
    fr.title,
    fr.production_year,
    fr.total_cast,
    COALESCE(fr.company_count, 0) AS company_count,
    COALESCE(fr.company_names, 'No Companies') AS company_names,
    CASE 
        WHEN fr.total_cast > 10 THEN 'Star-Studded'
        WHEN fr.total_cast > 0 THEN 'Moderate Cast'
        ELSE 'No Cast'
    END AS cast_label,
    CASE 
        WHEN fr.production_year IS NULL THEN 'Unknown Year'
        ELSE CAST(fr.production_year AS VARCHAR)
    END AS year_display,
    CONCAT(fr.title, ' (' , COALESCE(year_display, 'Unknown Year'), ')') AS title_display
FROM 
    FinalResults fr
WHERE 
    fr.production_year = (SELECT MAX(production_year) FROM title WHERE production_year IS NOT NULL)
ORDER BY 
    fr.total_cast DESC, fr.title;
