WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        a.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.person_id) DESC) AS rn
    FROM 
        aka_title t
    JOIN 
        movie_info mi ON t.id = mi.movie_id
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        cast_info c ON t.id = c.movie_id 
    JOIN 
        aka_name a ON c.person_id = a.person_id 
    GROUP BY 
        t.id, a.name, t.production_year
),
FilteredTitles AS (
    SELECT 
        title_id,
        title,
        production_year,
        actor_name
    FROM 
        RankedTitles
    WHERE 
        rn <= 5
)
SELECT 
    ft.title,
    ft.production_year,
    ft.actor_name,
    COUNT(DISTINCT mk.keyword_id) AS keyword_count,
    STRING_AGG(DISTINCT mk.keyword, ', ') AS keywords,
    SUM(CASE WHEN mc.company_type_id IN (SELECT id FROM company_type WHERE kind LIKE '%Production%') THEN 1 ELSE 0 END) AS production_company_count
FROM 
    FilteredTitles ft
JOIN 
    movie_keyword mk ON ft.title_id = mk.movie_id
JOIN 
    movie_companies mc ON ft.title_id = mc.movie_id
GROUP BY 
    ft.title_id, ft.title, ft.production_year, ft.actor_name
ORDER BY 
    ft.production_year DESC, keyword_count DESC;
