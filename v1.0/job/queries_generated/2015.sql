WITH RankedTitles AS (
    SELECT 
        a.id AS name_id,
        a.name,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY t.production_year DESC) AS title_rank
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    WHERE 
        t.production_year IS NOT NULL
),
FilteredTitles AS (
    SELECT 
        name_id,
        name,
        title,
        production_year
    FROM 
        RankedTitles
    WHERE 
        title_rank <= 5
),
PersonInfo AS (
    SELECT 
        p.person_id,
        pi.info_type_id,
        pi.info
    FROM 
        person_info pi
    JOIN 
        cast_info c ON pi.person_id = c.person_id
    JOIN 
        aka_name a ON a.person_id = c.person_id
)
SELECT 
    ft.name,
    ft.title,
    ft.production_year,
    CASE 
        WHEN p.info IS NULL THEN 'No Info'
        ELSE p.info
    END AS info,
    COUNT(DISTINCT c.movie_id) OVER (PARTITION BY ft.name_id) AS movie_count
FROM 
    FilteredTitles ft
LEFT JOIN 
    PersonInfo p ON ft.name_id = p.person_id
LEFT JOIN 
    cast_info c ON ft.name_id = c.person_id
WHERE 
    ft.production_year >= 2000
ORDER BY 
    ft.name, ft.production_year DESC;
