WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title mt ON ml.movie_id = mt.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    ak.name AS actor_name,
    at.title AS movie_title,
    at.production_year,
    COUNT(DISTINCT ac.id) AS total_roles,
    RANK() OVER (PARTITION BY ak.person_id ORDER BY COUNT(DISTINCT ac.id) DESC) AS role_rank,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
    COALESCE(ci.note, 'No note') AS role_note
FROM 
    aka_name ak
JOIN 
    cast_info ac ON ak.person_id = ac.person_id
JOIN 
    aka_title at ON ac.movie_id = at.id
LEFT JOIN 
    movie_keyword mk ON at.id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
LEFT JOIN 
    complete_cast cc ON at.id = cc.movie_id
LEFT JOIN 
    info_type it ON cc.status_id = it.id
LEFT JOIN 
    company_name cn ON ac.movie_id = cn.imdb_id 
LEFT JOIN 
    (SELECT DISTINCT movie_id, note FROM complete_cast WHERE note IS NOT NULL) ci ON ac.movie_id = ci.movie_id
WHERE 
    at.production_year > 2010 
    AND ak.name IS NOT NULL
GROUP BY 
    ak.name, at.title, at.production_year, ci.note
HAVING 
    COUNT(DISTINCT ac.id) > 1 
    AND COUNT(DISTINCT kw.id) > 0
ORDER BY 
    total_roles DESC, movie_title ASC;
