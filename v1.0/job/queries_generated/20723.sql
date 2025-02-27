WITH RECURSIVE movie_hierarchy AS (
    -- CTE to generate a hierarchy of titles along with their links recursively
    SELECT 
        m.id AS movie_id,
        t.title,
        COALESCE(l.linked_movie_id, 0) AS linked_movie_id,
        1 AS depth
    FROM 
        title t
    JOIN 
        movie_link l ON t.id = l.movie_id
    JOIN 
        aka_title m ON m.movie_id = t.imdb_id
    WHERE 
        t.production_year > 2000

    UNION ALL

    SELECT 
        mh.movie_id,
        t.title,
        COALESCE(l.linked_movie_id, 0),
        mh.depth + 1
    FROM 
        movie_hierarchy mh
    JOIN 
        movie_link l ON mh.linked_movie_id = l.movie_id
    JOIN 
        title t ON l.linked_movie_id = t.id
    WHERE 
        mh.depth < 5
)

SELECT 
    CONCAT(a.name, ' (', COALESCE(a.md5sum, 'Unknown'), ')') AS actor_name,
    t.title AS movie_title,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    COUNT(DISTINCT cc.person_id) AS num_cast_members,
    SUM(CASE WHEN cc.person_role_id IS NOT NULL THEN 1 ELSE 0 END) AS roles_filled,
    AVG(CASE WHEN mi.info IS NOT NULL THEN LENGTH(mi.info) ELSE NULL END) AS avg_info_length,
    ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT cc.person_id) DESC) AS rank
FROM 
    aka_name a
JOIN 
    cast_info cc ON a.person_id = cc.person_id
JOIN 
    title t ON cc.movie_id = t.id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = t.id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_info mi ON mi.movie_id = t.id AND mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'Rating')
LEFT JOIN 
    movie_hierarchy mh ON mh.movie_id = cc.movie_id
WHERE 
    a.name IS NOT NULL 
    AND t.production_year > 2000
    AND a.name NOT LIKE '%Unknown%' 
GROUP BY 
    a.id, t.id
HAVING 
    COUNT(DISTINCT cc.person_id) > 1 
    OR SUM(CASE WHEN cc.note IS NOT NULL THEN 1 ELSE 0 END) > 3
ORDER BY 
    rank, movie_title;
