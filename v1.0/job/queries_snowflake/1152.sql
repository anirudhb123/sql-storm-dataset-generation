
WITH RankedTitles AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.title, t.production_year
),
FilteredTitles AS (
    SELECT 
        rt.title,
        rt.production_year,
        rt.cast_count
    FROM 
        RankedTitles rt
    WHERE 
        rt.rank <= 5
),
MovieKeywords AS (
    SELECT 
        m.id AS movie_id,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY m.id ORDER BY k.keyword) AS keyword_rank,
        m.title  -- Added title for proper join later
    FROM 
        aka_title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
)
SELECT 
    ft.title,
    ft.production_year,
    ft.cast_count,
    LISTAGG(mk.keyword, ', ') WITHIN GROUP (ORDER BY mk.keyword) AS keywords,
    CASE 
        WHEN ft.cast_count IS NULL THEN 'No Cast'
        ELSE 'Has Cast'
    END AS cast_status
FROM 
    FilteredTitles ft
LEFT JOIN 
    MovieKeywords mk ON ft.title = mk.title
WHERE 
    mk.keyword_rank <= 3
GROUP BY 
    ft.title, ft.production_year, ft.cast_count
ORDER BY 
    ft.production_year DESC, ft.cast_count DESC;
