WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(ci.id) AS cast_count,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names
    FROM 
        title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    GROUP BY 
        t.id, t.title, t.production_year
),
FilteredTitles AS (
    SELECT 
        title_id,
        title,
        production_year,
        cast_count,
        cast_names,
        RANK() OVER (PARTITION BY production_year ORDER BY cast_count DESC) AS rank_within_year
    FROM 
        RankedTitles
)
SELECT 
    ft.title,
    ft.production_year,
    ft.cast_count,
    ft.cast_names,
    kt.kind AS title_kind
FROM 
    FilteredTitles ft
JOIN 
    kind_type kt ON (SELECT kind_id FROM title WHERE id = ft.title_id) = kt.id
WHERE 
    ft.rank_within_year <= 5
ORDER BY 
    ft.production_year DESC, 
    ft.cast_count DESC;
