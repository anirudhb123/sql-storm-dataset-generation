WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        0 AS depth
    FROM 
        aka_title t
    WHERE 
        t.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        m.id,
        m.title,
        m.production_year,
        depth + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        aka_title m ON mh.movie_id = m.episode_of_id
)
SELECT 
    a.name AS actor_name,
    STRING_AGG(DISTINCT th.title, ', ') AS titles,
    COUNT(DISTINCT th.movie_id) AS title_count,
    MAX(th.production_year) AS latest_year,
    AVG(COALESCE(j.status, 0)) AS avg_status,
    COUNT(DISTINCT j.person_id) AS unique_actors,
    SUM(CASE WHEN kw.keyword IS NOT NULL THEN 1 ELSE 0 END) AS keyword_count
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    MovieHierarchy th ON ci.movie_id = th.movie_id
LEFT JOIN 
    complete_cast j ON j.movie_id = th.movie_id
LEFT JOIN 
    movie_keyword mw ON th.movie_id = mw.movie_id
LEFT JOIN 
    keyword kw ON mw.keyword_id = kw.id
WHERE 
    a.name IS NOT NULL 
    AND a.name <> '' 
    AND th.production_year >= 2000
GROUP BY 
    a.name
HAVING 
    COUNT(DISTINCT th.movie_id) > 1
ORDER BY 
    title_count DESC, latest_year DESC;
