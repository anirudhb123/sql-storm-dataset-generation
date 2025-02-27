WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        c.movie_id AS parent_movie_id,
        c.subject_id AS actor_id,
        1 AS depth
    FROM 
        complete_cast c
    WHERE 
        c.status_id = 1  -- filter for valid cast members
    
    UNION ALL
    
    SELECT 
        mc.linked_movie_id AS parent_movie_id,
        mh.actor_id AS actor_id,
        mh.depth + 1
    FROM 
        movie_link mc
    JOIN 
        MovieHierarchy mh ON mc.movie_id = mh.parent_movie_id
)
SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    COUNT(DISTINCT mh.parent_movie_id) AS num_related_movies,
    SUM(CASE WHEN mc.company_id IS NOT NULL THEN 1 ELSE 0 END) AS num_company_links,
    AVG(CASE WHEN mi.info IS NOT NULL THEN LENGTH(mi.info) ELSE NULL END) AS avg_info_length,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id
LEFT JOIN 
    MovieHierarchy mh ON mh.actor_id = ci.person_id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id
WHERE 
    t.production_year >= 2000
    AND t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
GROUP BY 
    a.name, t.title, t.production_year
ORDER BY 
    num_related_movies DESC, avg_info_length DESC
LIMIT 50;

This SQL query creates a recursive CTE named `MovieHierarchy` to establish connections between movies and their cast members, and aggregates various information related to actors and their roles in movies produced after 2000. It combines multiple tables using outer joins, filters on kind types and production year, and utilizes window functions and string aggregations for a comprehensive analysis on performance benchmarking.
