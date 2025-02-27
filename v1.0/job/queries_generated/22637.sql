WITH RankedTitles AS (
    SELECT 
        t.title AS movie_title,
        aa.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.person_id) DESC) AS title_rank,
        t.production_year
    FROM 
        title t
    JOIN 
        aka_title at ON t.id = at.movie_id
    LEFT JOIN 
        cast_info c ON at.id = c.movie_id
    LEFT JOIN 
        aka_name aa ON c.person_id = aa.person_id
    GROUP BY 
        t.title, aa.name, t.production_year
),
AverageCast AS (
    SELECT 
        production_year, 
        AVG(actor_count) AS avg_actors
    FROM (
        SELECT 
            t.production_year, 
            COUNT(c.person_id) AS actor_count
        FROM 
            title t
        JOIN 
            aka_title at ON t.id = at.movie_id
        LEFT JOIN 
            cast_info c ON at.id = c.movie_id
        GROUP BY 
            t.production_year
    ) AS YearlyCounts
    GROUP BY 
        production_year
),
TopYears AS (
    SELECT 
        production_year
    FROM 
        AverageCast
    WHERE 
        avg_actors > (SELECT AVG(avg_actors) FROM AverageCast)
),
FilteredTitles AS (
    SELECT 
        rt.movie_title,
        rt.actor_name,
        rt.production_year
    FROM 
        RankedTitles rt
    JOIN 
        TopYears ty ON rt.production_year = ty.production_year
    WHERE 
        rt.title_rank <= 3
)
SELECT 
    ft.movie_title,
    ft.actor_name,
    ft.production_year,
    CASE 
        WHEN ft.production_year < 2000 THEN 'Pre-2000'
        WHEN ft.production_year BETWEEN 2000 AND 2010 THEN '2000s'
        ELSE '2011 and onwards'
    END AS era,
    CONCAT(ft.actor_name, ' starred in ', ft.movie_title, ' released in ', ft.production_year) AS description,
    NULLIF(NULLIF(ft.production_year, 0), NULL) AS safe_year,
    COUNT(DISTINCT c.person_id) OVER (PARTITION BY ft.production_year) AS distinct_cast_count
FROM 
    FilteredTitles ft
LEFT JOIN 
    cast_info c ON ft.movie_title = c.movie_id
ORDER BY 
    ft.production_year DESC, 
    ft.actor_name;
