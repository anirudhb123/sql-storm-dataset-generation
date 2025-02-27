WITH ranked_titles AS (
    SELECT 
        a.id AS aka_id,
        a.name AS aka_name,
        t.id AS title_id,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY t.production_year DESC) AS rank
    FROM 
        aka_name a
    INNER JOIN 
        cast_info c ON a.person_id = c.person_id
    INNER JOIN 
        aka_title t ON c.movie_id = t.movie_id
    WHERE 
        a.name IS NOT NULL AND t.production_year >= 2000
),
aggregated_info AS (
    SELECT 
        aka_id,
        aka_name,
        COUNT(title_id) AS title_count,
        STRING_AGG(movie_title, ', ') AS all_titles,
        MAX(production_year) AS latest_year
    FROM 
        ranked_titles
    WHERE 
        rank <= 5
    GROUP BY 
        aka_id, aka_name
),
final_output AS (
    SELECT 
        a.id AS person_id,
        a.name AS person_name,
        ai.title_count,
        ai.all_titles,
        ai.latest_year
    FROM 
        aka_name a
    LEFT JOIN 
        aggregated_info ai ON a.id = ai.aka_id
    WHERE 
        a.name LIKE 'A%' OR a.name LIKE 'B%'
)
SELECT 
    f.person_id,
    f.person_name,
    COALESCE(f.title_count, 0) AS title_count,
    COALESCE(f.all_titles, 'No titles') AS all_titles,
    COALESCE(f.latest_year, 'No year') AS latest_year
FROM 
    final_output f
ORDER BY 
    f.title_count DESC, 
    f.latest_year DESC;
