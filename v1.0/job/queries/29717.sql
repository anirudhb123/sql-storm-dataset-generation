WITH RankedTitles AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(mk.id) AS keyword_count,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY t.production_year DESC) AS rank
    FROM 
        title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
FilteredTitles AS (
    SELECT 
        rt.title,
        rt.production_year,
        rt.keyword_count
    FROM 
        RankedTitles rt
    WHERE 
        rt.keyword_count > 5
),
CastDetails AS (
    SELECT 
        ci.movie_id,
        COUNT(ci.person_id) AS cast_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
)
SELECT 
    ft.title,
    ft.production_year,
    ft.keyword_count,
    cd.cast_count
FROM 
    FilteredTitles ft
JOIN 
    CastDetails cd ON ft.title = (SELECT title FROM title WHERE id = cd.movie_id)
ORDER BY 
    ft.production_year DESC, 
    ft.keyword_count DESC;