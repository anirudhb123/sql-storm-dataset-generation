WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year BETWEEN 2000 AND 2020
),
actor_movies AS (
    SELECT 
        a.person_id,
        a.id AS actor_id,
        a.name,
        c.movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY t.production_year DESC) AS movie_rank
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.id
    WHERE 
        c.person_role_id IN (SELECT id FROM role_type WHERE role LIKE 'actor%')
),
movie_keywords AS (
    SELECT
        mk.movie_id,
        g.keyword,
        COUNT(g.id) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        keyword g ON mk.keyword_id = g.id
    GROUP BY 
        mk.movie_id, g.keyword
),
popular_movies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT ca.person_id) AS actor_count,
        SUM(mk.keyword_count) AS total_keywords
    FROM 
        ranked_titles t
    JOIN 
        actor_movies ca ON t.title_id = ca.movie_id
    LEFT JOIN 
        movie_keywords mk ON t.title_id = mk.movie_id
    GROUP BY 
        t.title, t.production_year
)
SELECT 
    pm.title,
    pm.production_year,
    pm.actor_count,
    pm.total_keywords,
    CASE 
        WHEN pm.actor_count > 5 THEN 'Highly Popular'
        WHEN pm.total_keywords > 10 THEN 'Keyword Rich'
        ELSE 'Average'
    END AS movie_category
FROM 
    popular_movies pm
WHERE 
    pm.total_keywords > 5
ORDER BY 
    pm.production_year DESC, pm.actor_count DESC;