WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT mc.company_id) AS company_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names
    FROM 
        title t
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        aka_title ak ON t.id = ak.movie_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
),
FilteredTitles AS (
    SELECT 
        rt.title_id,
        rt.title,
        rt.production_year,
        rt.company_count,
        rt.aka_names,
        ROW_NUMBER() OVER (PARTITION BY rt.production_year ORDER BY rt.company_count DESC) AS rank_within_year
    FROM 
        RankedTitles rt
    WHERE 
        rt.company_count > 1
)
SELECT 
    ft.title_id,
    ft.title,
    ft.production_year,
    ft.company_count,
    ft.aka_names
FROM 
    FilteredTitles ft
WHERE 
    ft.rank_within_year <= 10
ORDER BY 
    ft.production_year DESC, 
    ft.company_count DESC;
This query benchmarks string processing by aggregating data from the `title`, `movie_companies`, and `aka_title` tables. It ranks movies produced after 2000 based on the number of companies associated with them and also lists associated alternative names. The final result includes the top 10 ranked titles per production year in descending order.
