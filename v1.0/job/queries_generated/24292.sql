WITH RECURSIVE title_hierarchy AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.episode_of_id,
        1 AS level
    FROM 
        title t
    WHERE 
        t.season_nr IS NULL

    UNION ALL

    SELECT 
        t.id AS title_id,
        CONCAT(t.title, ' (Episode ', t.episode_nr, ')') AS title,
        t.production_year,
        t.episode_of_id,
        th.level + 1 AS level
    FROM 
        title t
    JOIN 
        title_hierarchy th ON t.episode_of_id = th.title_id
)

SELECT 
    a.name AS actor_name,
    COALESCE(t.title, 'N/A') AS movie_title,
    COUNT(DISTINCT mc.company_id) AS production_companies,
    AVG(CASE 
        WHEN m.production_year BETWEEN 1990 AND 2000 THEN 1 
        ELSE NULL 
    END) AS avg_90s_movies,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY COUNT(DISTINCT m.id) DESC) AS actor_rank
FROM 
    aka_name a
LEFT JOIN 
    cast_info c ON a.person_id = c.person_id
LEFT JOIN 
    title_hierarchy th ON c.movie_id = th.title_id
LEFT JOIN 
    movie_companies mc ON mc.movie_id = c.movie_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = c.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    title m ON c.movie_id = m.id
WHERE 
    a.name IS NOT NULL
    AND (m.production_year IS NULL OR m.production_year > 1980)
GROUP BY 
    a.name, t.title
HAVING 
    COUNT(DISTINCT m.id) > 2 
    AND COUNT(DISTINCT mc.company_id) > 1
ORDER BY 
    actor_rank, production_companies DESC;
