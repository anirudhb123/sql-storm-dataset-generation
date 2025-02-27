WITH RECURSIVE RecursiveCTE AS (
    SELECT 
        c.movie_id,
        c.person_id,
        1 AS level
    FROM 
        cast_info c
    WHERE 
        c.nr_order = 1

    UNION ALL

    SELECT 
        c.movie_id,
        c.person_id,
        r.level + 1
    FROM 
        cast_info c
    JOIN 
        RecursiveCTE r ON c.movie_id = r.movie_id 
    WHERE 
        c.nr_order = r.level + 1
),
CTE_MovieTitles AS (
    SELECT 
        t.title,
        t.production_year,
        a.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY r.level DESC) AS actor_level
    FROM 
        title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    LEFT JOIN 
        aka_name a ON ci.person_id = a.person_id
    LEFT JOIN 
        RecursiveCTE r ON ci.movie_id = r.movie_id
    WHERE 
        t.production_year IS NOT NULL
),
FilteredTitles AS (
    SELECT 
        title,
        production_year,
        actor_name
    FROM 
        CTE_MovieTitles
    WHERE 
        actor_level = 1 OR actor_name IS NOT NULL
)
SELECT 
    ft.title,
    ft.production_year,
    COUNT(DISTINCT ft.actor_name) AS actor_count,
    STRING_AGG(DISTINCT ft.actor_name, ', ') AS actors,
    COALESCE(MIN(bmi.info), 'No Info') AS movie_info
FROM 
    FilteredTitles ft
LEFT JOIN 
    movie_info bmi ON ft.production_year = bmi.movie_id AND bmi.info_type_id = (SELECT id FROM info_type WHERE info = 'Rating' LIMIT 1)
GROUP BY 
    ft.title, ft.production_year
HAVING 
    COUNT(DISTINCT ft.actor_name) > 1
ORDER BY 
    ft.production_year DESC, actor_count DESC
LIMIT 100
OFFSET 0;
