WITH RankedTitles AS (
    SELECT 
        a.id AS aka_id,
        a.name AS aka_name,
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY t.production_year DESC) AS year_rank
    FROM 
        aka_name a
    LEFT JOIN 
        aka_title t ON a.id = t.id
    WHERE 
        t.production_year IS NOT NULL
),
FilteredTitles AS (
    SELECT 
        rt.*, 
        CASE 
            WHEN rt.production_year >= 2000 THEN 'Modern'
            WHEN rt.production_year < 2000 AND rt.production_year >= 1980 THEN 'Classic'
            ELSE 'Vintage'
        END AS era
    FROM 
        RankedTitles rt
    WHERE 
        rt.year_rank <= 5
),
AggregateData AS (
    SELECT 
        ft.aka_name,
        COUNT(ft.title_id) AS title_count,
        MIN(ft.production_year) AS first_year,
        MAX(ft.production_year) AS last_year,
        STRING_AGG(DISTINCT ft.title, ', ') AS titles_list,
        SUM(CASE WHEN ft.era = 'Modern' THEN 1 ELSE 0 END) AS modern_count
    FROM 
        FilteredTitles ft
    GROUP BY 
        ft.aka_name
)
SELECT 
    ad.*, 
    CASE 
        WHEN ad.first_year IS NULL THEN 'No titles found'
        WHEN ad.first_year < 1980 THEN 'Vintage actor'
        WHEN ad.modern_count > 0 THEN 'Has modern titles'
        ELSE 'Classic actor only'
    END AS actor_category,
    ROW_NUMBER() OVER (ORDER BY ad.title_count DESC) AS rank,
    ad.titles_list || ' | Total Titles: ' || ad.title_count AS title_summary
FROM 
    AggregateData ad
ORDER BY 
    ad.title_count DESC, ad.first_year ASC
LIMIT 10;
