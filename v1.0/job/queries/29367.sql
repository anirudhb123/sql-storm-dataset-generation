
WITH RankedTitles AS (
    SELECT 
        t.id AS title_id, 
        t.title AS movie_title, 
        t.production_year,
        COUNT(DISTINCT a.id) AS actor_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names
    FROM 
        aka_title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        t.id, t.title, t.production_year
),
FilteredTitles AS (
    SELECT 
        title_id, 
        movie_title, 
        production_year, 
        actor_count, 
        actor_names,
        ROW_NUMBER() OVER (ORDER BY actor_count DESC, production_year DESC) AS rank
    FROM 
        RankedTitles
    WHERE 
        production_year >= 2000
)

SELECT 
    f.title_id,
    f.movie_title,
    f.production_year,
    f.actor_count,
    f.actor_names,
    i.info
FROM 
    FilteredTitles f
LEFT JOIN 
    movie_info i ON f.title_id = i.movie_id
WHERE 
    i.info_type_id IN (SELECT id FROM info_type WHERE info LIKE '%Box Office%')
ORDER BY 
    f.actor_count DESC, f.production_year DESC
LIMIT 10;
