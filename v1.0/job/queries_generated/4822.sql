WITH RankedTitles AS (
    SELECT 
        a.id AS aka_id,
        a.name AS aka_name,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY a.person_id ORDER BY t.production_year DESC) AS rank_desc,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    LEFT JOIN 
        movie_keyword mk ON t.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year IS NOT NULL AND 
        t.production_year > 2000
    GROUP BY 
        a.id, a.person_id, t.title, t.production_year
),
FilteredTitles AS (
    SELECT 
        aka_id,
        aka_name,
        title,
        production_year,
        keywords
    FROM 
        RankedTitles
    WHERE 
        rank_desc <= 3
),
TitleInfo AS (
    SELECT 
        ft.aka_name,
        ft.title,
        ft.production_year,
        COUNT(*) OVER (PARTITION BY ft.aka_id) AS movie_count
    FROM 
        FilteredTitles ft
)
SELECT 
    ti.aka_name,
    ti.title,
    ti.production_year,
    ti.movie_count,
    COALESCE(SUM(CASE WHEN c.note IS NOT NULL THEN 1 ELSE 0 END), 0) AS notes_with_content
FROM 
    TitleInfo ti
LEFT JOIN 
    cast_info c ON ti.aka_id = c.person_id
GROUP BY 
    ti.aka_name, ti.title, ti.production_year, ti.movie_count
ORDER BY 
    ti.production_year DESC, ti.movie_count DESC;
