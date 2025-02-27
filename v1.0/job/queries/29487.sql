WITH RecursiveTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        kt.kind AS kind,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names
    FROM 
        title t
    JOIN 
        kind_type kt ON t.kind_id = kt.id
    LEFT JOIN 
        aka_title at ON t.id = at.movie_id
    LEFT JOIN 
        aka_name ak ON ak.id = at.id
    GROUP BY 
        t.id, t.title, t.production_year, kt.kind
),
ProcessedTitles AS (
    SELECT 
        rt.title_id,
        rt.title,
        rt.kind,
        rt.production_year,
        LOWER(rt.title) AS lowered_title
    FROM 
        RecursiveTitles rt
),
FilteredTitles AS (
    SELECT 
        pt.title_id,
        pt.title,
        pt.kind,
        pt.production_year,
        pt.lowered_title,
        CASE 
            WHEN POSITION('action' IN pt.lowered_title) > 0 THEN 'Action'
            WHEN POSITION('drama' IN pt.lowered_title) > 0 THEN 'Drama'
            WHEN POSITION('comedy' IN pt.lowered_title) > 0 THEN 'Comedy'
            ELSE 'Other'
        END AS genre_classification
    FROM 
        ProcessedTitles pt
),
TitleStats AS (
    SELECT 
        ft.genre_classification,
        COUNT(*) AS total_titles,
        MIN(ft.production_year) AS earliest_release,
        MAX(ft.production_year) AS latest_release
    FROM 
        FilteredTitles ft
    GROUP BY 
        ft.genre_classification
)
SELECT 
    ts.genre_classification,
    ts.total_titles,
    ts.earliest_release,
    ts.latest_release,
    ROUND((EXTRACT(YEAR FROM cast('2024-10-01' as date)) - ts.earliest_release) / NULLIF(ts.total_titles, 0), 2) AS average_years_per_title
FROM 
    TitleStats ts
ORDER BY 
    ts.total_titles DESC;