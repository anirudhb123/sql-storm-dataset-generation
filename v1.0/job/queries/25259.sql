WITH RankedTitles AS (
    SELECT 
        a.title,
        a.production_year,
        k.keyword,
        RANK() OVER (PARTITION BY a.production_year ORDER BY LENGTH(a.title) DESC) AS title_rank
    FROM 
        aka_title a
    JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        a.production_year IS NOT NULL
),
FilteredTitles AS (
    SELECT 
        rt.title,
        rt.production_year,
        rt.keyword
    FROM 
        RankedTitles rt
    WHERE 
        rt.title_rank <= 10
),
TitleCounts AS (
    SELECT 
        ft.production_year,
        COUNT(ft.title) AS title_count,
        STRING_AGG(ft.title, ', ') AS title_list
    FROM 
        FilteredTitles ft
    GROUP BY 
        ft.production_year
)
SELECT 
    tc.production_year,
    tc.title_count,
    tc.title_list,
    (SELECT COUNT(*) FROM aka_title a WHERE a.production_year = tc.production_year) AS total_titles_in_year
FROM 
    TitleCounts tc
ORDER BY 
    tc.production_year DESC;
