WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        0 AS level,
        m.id AS root_movie_id
    FROM 
        aka_title m 
    WHERE 
        m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        level + 1,
        h.root_movie_id
    FROM 
        aka_title m
    INNER JOIN 
        movie_link ml ON m.id = ml.linked_movie_id
    INNER JOIN 
        MovieHierarchy h ON ml.movie_id = h.movie_id
)

SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    mh.level,
    COALESCE(a.name, c.name) AS actor_name,
    COUNT(DISTINCT kc.keyword) AS keyword_count,
    SUM(CASE WHEN pc.info IS NOT NULL THEN 1 ELSE 0 END) AS has_person_info,
    STRING_AGG(DISTINCT ci.note, '; ') AS casting_notes
FROM 
    MovieHierarchy mh
LEFT JOIN 
    cast_info ci ON mh.movie_id = ci.movie_id
LEFT JOIN 
    aka_name a ON ci.person_id = a.person_id
LEFT JOIN 
    char_name c ON a.name = c.name
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    keyword kc ON mk.keyword_id = kc.id
LEFT JOIN 
    person_info pc ON ci.person_id = pc.person_id 
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, mh.level, a.name, c.name
HAVING 
    COUNT(DISTINCT mk.keyword_id) > 2 AND 
    SUM(CASE WHEN pc.info IS NOT NULL THEN 1 ELSE 0 END) > 0
ORDER BY 
    mh.production_year DESC, mh.title ASC;
