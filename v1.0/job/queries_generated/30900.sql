WITH RECURSIVE FilmSeries AS (
    SELECT 
        t.id as title_id,
        t.title,
        t.production_year,
        CASE 
            WHEN t.episode_of_id IS NOT NULL THEN 1 
            ELSE 0 
        END AS is_episode
    FROM 
        title t
    WHERE 
        t.season_nr IS NOT NULL
    
    UNION ALL
    
    SELECT 
        t.id,
        t.title,
        t.production_year,
        CASE 
            WHEN t.episode_of_id IS NOT NULL THEN 1 
            ELSE 0 
        END AS is_episode
    FROM 
        title t
    INNER JOIN FilmSeries fs ON t.episode_of_id = fs.title_id
)
SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    COALESCE(CAST(NULLIF(t.production_year, 0) AS VARCHAR), 'Year Not Available') AS production_year,
    STRING_AGG(k.keyword, ', ') AS keywords,
    COUNT(DISTINCT cc.movie_id) AS total_movies,
    AVG(CASE WHEN mc.company_id IS NOT NULL THEN 1 ELSE 0 END) OVER (PARTITION BY a.person_id) AS avg_company_involvement,
    SUM(CASE 
            WHEN c.nr_order IS NOT NULL 
            THEN 1 ELSE 0 
        END) AS total_roles
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id
LEFT JOIN 
    complete_cast cc ON t.id = cc.movie_id
WHERE 
    a.name IS NOT NULL
    AND t.production_year > 2000 
    AND t.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE 'movie%')
GROUP BY 
    a.name, t.title, t.production_year
HAVING 
    COUNT(DISTINCT c.movie_id) > 5 
ORDER BY 
    total_movies DESC, actor_name ASC;
