WITH RECURSIVE actor_hierarchy AS (
    SELECT 
        c.person_id,
        a.name AS actor_name,
        t.title,
        CTE_movie.year,
        level,
        ROW_NUMBER() OVER (PARTITION BY c.person_id ORDER BY t.production_year DESC) AS row_num
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    LEFT JOIN (
        SELECT 
            m.movie_id,
            m.production_year,
            COUNT(DISTINCT mc.company_id) AS company_count
        FROM
            movie_companies mc
        JOIN 
            aka_title m ON mc.movie_id = m.movie_id
        GROUP BY m.movie_id, m.production_year
    ) CTE_movie ON c.movie_id = CTE_movie.movie_id
    WHERE 
        t.production_year IS NOT NULL AND 
        (c.note IS NULL OR c.note NOT LIKE '%cameo%')

    UNION ALL

    SELECT 
        c.person_id,
        a.name AS actor_name,
        t.title,
        CTE_movie.year,
        level + 1,
        ROW_NUMBER() OVER (PARTITION BY c.person_id ORDER BY t.production_year DESC) AS row_num
    FROM
        actor_hierarchy ah
    JOIN 
        cast_info c ON c.movie_id = ah.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    LEFT JOIN (
        SELECT 
            m.movie_id,
            m.production_year,
            COUNT(DISTINCT mc.company_id) AS company_count
        FROM
            movie_companies mc
        JOIN 
            aka_title m ON mc.movie_id = m.movie_id
        GROUP BY m.movie_id, m.production_year
    ) CTE_movie ON c.movie_id = CTE_movie.movie_id
    WHERE 
        (ah.row_num < 5) AND 
        (t.production_year IS NOT NULL) AND 
        (c.note IS NULL OR c.note NOT LIKE '%cameo%')
),

filtered_cast AS (
    SELECT 
        ah.person_id,
        ah.actor_name,
        ah.title,
        ah.year,
        ah.level
    FROM 
        actor_hierarchy ah
    WHERE 
        ah.level > 1 OR 
        (ah.level = 1 AND ah.actor_name NOT IN (
            SELECT 
                DISTINCT a1.name 
            FROM actor_hierarchy a1
            WHERE a1.level = 1 AND a1.actor_name IS NOT NULL
        ))
)

SELECT 
    c.actor_name,
    COUNT(DISTINCT c.title) AS title_count,
    STRING_AGG(DISTINCT c.title, ', ') AS titles,
    SUM(CASE 
            WHEN c.year BETWEEN 2000 AND 2010 THEN 1 
            ELSE 0 
        END) AS count_2000s,
    COALESCE(MAX(c.year), 'Unknown') AS latest_year
FROM 
    filtered_cast c
GROUP BY 
    c.actor_name
HAVING 
    COUNT(DISTINCT c.title) > 3
ORDER BY 
    title_count DESC, 
    latest_year DESC;
