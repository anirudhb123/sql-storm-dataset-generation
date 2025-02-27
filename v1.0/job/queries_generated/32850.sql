WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title AS mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        ak.title,
        ak.production_year,
        mh.level + 1
    FROM 
        MovieHierarchy AS mh
    JOIN 
        movie_link AS ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title AS ak ON ml.linked_movie_id = ak.id
)
SELECT 
    CONCAT(a.name, ' (', a.id, ')') AS actor_name,
    m.title AS movie_title,
    m.production_year,
    COALESCE(CAST(COUNT(DISTINCT cm.company_id) AS TEXT), 'None') AS company_count,
    MAX(mh.level) AS max_hierarchical_level,
    STRING_AGG(DISTINCT k.keyword, ', ') FILTER (WHERE k.keyword IS NOT NULL) AS associated_keywords
FROM 
    aka_name AS a
JOIN 
    cast_info AS ci ON a.person_id = ci.person_id
JOIN 
    aka_title AS m ON ci.movie_id = m.id
LEFT JOIN 
    movie_companies AS mc ON m.id = mc.movie_id
LEFT JOIN 
    company_name AS c ON mc.company_id = c.id
LEFT JOIN 
    movie_keyword AS mk ON m.id = mk.movie_id
LEFT JOIN 
    keyword AS k ON mk.keyword_id = k.id
JOIN 
    MovieHierarchy AS mh ON m.id = mh.movie_id
WHERE 
    a.name IS NOT NULL
    AND (m.production_year >= 2000 OR m.production_year IS NULL)
GROUP BY 
    a.name, m.title, m.production_year
ORDER BY 
    m.production_year DESC, actor_name ASC;
