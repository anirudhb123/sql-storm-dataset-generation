WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id, 
        mt.title AS movie_title, 
        mt.production_year,
        1 AS depth
    FROM 
        aka_title AS mt
    WHERE 
        mt.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.depth + 1
    FROM 
        MovieHierarchy AS mh
    JOIN 
        movie_link AS ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title AS at ON ml.linked_movie_id = at.id
)

SELECT 
    ak.name AS actor_name,
    at.title AS movie_title,
    mh.production_year,
    COUNT(DISTINCT cc.person_id) AS total_cast,
    AVG(CASE WHEN ci.note IS NULL THEN 0 ELSE 1 END) AS note_presence,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS related_keywords
FROM 
    MovieHierarchy AS mh
JOIN 
    cast_info AS ci ON mh.movie_id = ci.movie_id
JOIN 
    aka_name AS ak ON ci.person_id = ak.person_id
JOIN 
    movie_keyword AS mk ON mh.movie_id = mk.movie_id
JOIN 
    keyword AS kw ON mk.keyword_id = kw.id
JOIN 
    aka_title AS at ON mh.movie_id = at.id
WHERE 
    ak.name IS NOT NULL
    AND ak.md5sum IS NOT NULL
    AND mh.depth <= 2
GROUP BY 
    ak.name, at.title, mh.production_year
HAVING 
    COUNT(DISTINCT ci.person_id) > 1
ORDER BY 
    mh.production_year DESC, total_cast DESC;
