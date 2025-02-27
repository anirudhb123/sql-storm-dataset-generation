WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        1 AS level,
        ARRAY[mt.id] AS path
    FROM 
        aka_title mt
    WHERE 
        mt.production_year < 2000

    UNION ALL

    SELECT 
        lc.linked_movie_id,
        at.title,
        at.production_year,
        at.kind_id,
        mh.level + 1,
        mh.path || lc.linked_movie_id
    FROM 
        movie_link lc
    JOIN 
        aka_title at ON lc.linked_movie_id = at.id
    JOIN 
        movie_hierarchy mh ON lc.movie_id = mh.movie_id
    WHERE 
        lc.link_type_id = (SELECT id FROM link_type WHERE link = 'sequel')
)
SELECT 
    ak.name AS actor_name,
    at.title AS movie_title,
    mh.production_year,
    mh.level,
    string_agg(DISTINCT kw.keyword, ', ') AS keywords,
    COUNT(DISTINCT mi.info) AS info_count,
    AVG(CASE WHEN ci.note IS NOT NULL THEN 1 END) AS cast_note_exists,
    COUNT(DISTINCT c.id) AS cast_count
FROM 
    movie_hierarchy mh
JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
JOIN 
    cast_info ci ON cc.id = ci.movie_id
JOIN 
    aka_name ak ON ci.person_id = ak.person_id
JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
JOIN 
    keyword kw ON mk.keyword_id = kw.id
LEFT JOIN 
    movie_info mi ON mh.movie_id = mi.movie_id AND mi.info_type_id NOT IN (SELECT id FROM info_type WHERE info = 'reserved')
LEFT JOIN 
    role_type rt ON ci.role_id = rt.id
LEFT JOIN 
    title t ON mh.movie_id = t.id
WHERE 
    mh.level <= 3 
    AND mh.production_year IS NOT NULL 
    AND ak.name IS NOT NULL
GROUP BY 
    ak.name, mh.production_year, mh.level, mh.title
ORDER BY 
    COUNT(DISTINCT mk.keyword_id) DESC,
    mh.production_year DESC,
    ak.name
LIMIT 1000;

-- This query generates a recursive CTE to explore a hierarchy of movies based on sequels. 
-- It combines various elements: outer joins, correlated subqueries, window functions, 
-- string aggregation, and uses NULL logic to make complex conditions for the movie's 
-- information and actors. The conditions intentionally create obscure corner cases.
