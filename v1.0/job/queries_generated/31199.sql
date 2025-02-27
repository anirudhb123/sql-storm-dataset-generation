WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        1 AS level
    FROM 
        aka_title t
    WHERE 
        t.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        mc.linked_movie_id AS movie_id,
        t.title,
        t.production_year,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title t ON ml.linked_movie_id = t.id
)
SELECT 
    a.name AS actor_name,
    COUNT(DISTINCT mc.movie_id) AS movie_count,
    AVG(mh.level) AS avg_hierarchy_level,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    CASE 
        WHEN COUNT(DISTINCT mc.movie_id) > 5 THEN 'Veteran Actor'
        ELSE 'Rising Star'
    END AS actor_status
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    movie_companies mc ON ci.movie_id = mc.movie_id
LEFT JOIN 
    movie_keyword mk ON mc.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    MovieHierarchy mh ON mc.movie_id = mh.movie_id
WHERE 
    a.name IS NOT NULL AND 
    a.name != '' AND 
    ci.role_id IN (SELECT id FROM role_type WHERE role IN ('Actor', 'Supporting Actor'))
GROUP BY 
    a.name
HAVING 
    COUNT(DISTINCT mc.movie_id) > 3
ORDER BY 
    movie_count DESC, 
    avg_hierarchy_level ASC;

This SQL query creates a recursive common table expression (CTE) named `MovieHierarchy` that retrieves all movies produced after 2000 along with their hierarchical relationships using the `movie_link` table. The main query then joins multiple tables to gather information about actors, the number of movies they've appeared in, the average hierarchy level of the movies, keywords associated with those movies, and categorizes the actors as either 'Veteran Actor' or 'Rising Star' based on their movie count. The results are filtered to include only actors who have appeared in more than three movies and are sorted by the number of movies (in descending order) and the average hierarchy level (in ascending order).
