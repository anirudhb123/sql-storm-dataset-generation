WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COALESCE(c.title, 'Original') AS parent_title,
        0 AS level
    FROM 
        aka_title AS t
    LEFT JOIN 
        aka_title AS c ON t.episode_of_id = c.id
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        t.id,
        t.title,
        t.production_year,
        mh.title,
        mh.level + 1
    FROM 
        aka_title AS t
    INNER JOIN 
        MovieHierarchy AS mh ON t.episode_of_id = mh.movie_id
)
SELECT 
    mh.movie_id,
    mh.title AS movie_title,
    mh.production_year,
    mh.parent_title,
    round(AVG(mk_count), 2) AS avg_keyword_count,
    STRING_AGG(DISTINCT ak.name, ', ') AS actor_names,
    COUNT(DISTINCT ci.person_id) AS total_cast,
    MAX(CASE WHEN ci.role_id = (SELECT id FROM role_type WHERE role = 'Director') THEN ci.person_id END) AS director_id,
    COUNT(DISTINCT CASE WHEN ci.nr_order IS NOT NULL THEN ci.person_id END) AS credited_cast,
    COUNT(ci.person_id) FILTER (WHERE ci.note IS NULL) AS uncredited_actors,
    SUM(CASE WHEN ci.note LIKE '%cameo%' THEN 1 ELSE 0 END) AS cameo_count
FROM 
    MovieHierarchy AS mh
LEFT JOIN 
    movie_keyword AS mk ON mk.movie_id = mh.movie_id
LEFT JOIN 
    movie_companies AS mc ON mc.movie_id = mh.movie_id
LEFT JOIN 
    cast_info AS ci ON ci.movie_id = mh.movie_id
LEFT JOIN 
    aka_name AS ak ON ak.person_id = ci.person_id
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, mh.parent_title
HAVING 
    COUNT(DISTINCT ci.person_id) > 0 AND
    ROUND(AVG(mk_count), 2) > 1
ORDER BY 
    mh.production_year DESC, 
    avg_keyword_count DESC 
LIMIT 100;

This query produces a comprehensive report on movies, particularly focusing on their cast, keywords, and hierarchical relationships within series. It utilizes a recursive Common Table Expression (CTE) to build a hierarchy of movies and includes various aggregate functions to gather statistics around the cast and keywords associated with each movie, while also integrating outer joins and complicated predicates for nuanced data handling.
