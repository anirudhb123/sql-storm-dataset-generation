
WITH RECURSIVE actor_hierarchy AS (
    SELECT 
        c.person_id,
        a.name AS actor_name,
        c.movie_id,
        ROW_NUMBER() OVER (PARTITION BY c.person_id ORDER BY c.nr_order) AS act_order
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id 
    WHERE 
        a.name IS NOT NULL
),

movies_with_keywords AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        t.id, t.title
),

cast_info_enriched AS (
    SELECT 
        a.actor_name,
        m.title,
        CASE 
            WHEN m.keywords LIKE '%Thriller%' THEN 'Thriller'
            WHEN m.keywords LIKE '%Comedy%' THEN 'Comedy'
            ELSE 'Other'
        END AS genre,
        ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY m.title) AS row_num
    FROM 
        actor_hierarchy a
    JOIN 
        movies_with_keywords m ON a.movie_id = m.movie_id
    WHERE 
        a.act_order <= 3 
),

company_movies AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS total_companies
    FROM 
        movie_companies mc
    GROUP BY 
        mc.movie_id
),

final_results AS (
    SELECT
        c.actor_name,
        c.title,
        c.genre,
        cm.total_companies
    FROM 
        cast_info_enriched c
    LEFT JOIN 
        company_movies cm ON c.title = (SELECT title FROM movies_with_keywords WHERE movie_id = cm.movie_id)
    WHERE 
        c.genre != 'Other'
)

SELECT 
    actor_name,
    title,
    genre,
    COALESCE(total_companies, 0) AS total_companies,
    CASE 
        WHEN total_companies IS NULL THEN 'No companies associated'
        ELSE 'Companies associated found'
    END AS company_status
FROM 
    final_results
ORDER BY 
    genre, actor_name;
