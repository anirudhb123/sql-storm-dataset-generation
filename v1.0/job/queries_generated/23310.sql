WITH ranked_titles AS (
    SELECT 
        a.id AS aka_id,
        a.name AS aka_name,
        t.id AS title_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY a.person_id ORDER BY t.production_year DESC) AS title_rank
    FROM 
        aka_name a
    JOIN 
        aka_title t ON a.id = t.id
    WHERE 
        t.production_year IS NOT NULL
),
cast_info_with_ranks AS (
    SELECT 
        c.id AS cast_id,
        c.person_id,
        c.movie_id,
        c.nr_order,
        a.name AS actor_name,
        RANK() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS role_rank
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
)

SELECT 
    r.aka_name,
    r.title,
    r.production_year,
    c.actor_name,
    c.role_rank,
    CASE 
        WHEN r.title_rank = 1 THEN 'Latest Title'
        ELSE 'Earlier Title'
    END AS title_status,
    (SELECT COUNT(*) 
     FROM movie_keyword mk 
     WHERE mk.movie_id = c.movie_id) AS keyword_count,
    COALESCE(NULLIF(c.nr_order, 0), 'N/A') AS display_order,
    CONCAT(r.title, ' - ', COALESCE(a.name, 'Unknown')) AS full_title
FROM 
    ranked_titles r
LEFT JOIN 
    cast_info_with_ranks c ON r.title_id = c.movie_id
LEFT JOIN 
    aka_name a ON c.person_id = a.person_id
WHERE 
    (c.role_rank <= 3 OR r.title_rank = 1)
    AND (r.production_year > 2000 OR r.production_year IS NULL)
ORDER BY 
    r.production_year DESC, 
    c.role_rank ASC;

