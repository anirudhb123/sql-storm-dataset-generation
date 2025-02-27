WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.depth + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    ak.name AS actor_name,
    att.title AS movie_title,
    att.production_year,
    COUNT(DISTINCT k.keyword) AS keyword_count,
    AVG(length(ai.info)) AS avg_actor_info_length,
    MAX(mh.depth) AS max_depth
FROM 
    cast_info ci
JOIN 
    aka_name ak ON ci.person_id = ak.person_id
JOIN 
    aka_title att ON ci.movie_id = att.movie_id
LEFT JOIN 
    movie_keyword mk ON att.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    person_info ai ON ak.person_id = ai.person_id
JOIN 
    movie_hierarchy mh ON att.id = mh.movie_id
WHERE 
    att.production_year >= 2000
AND 
    ak.name IS NOT NULL
GROUP BY 
    ak.name, att.title, att.production_year
HAVING 
    COUNT(DISTINCT k.keyword) > 1
ORDER BY 
    avg_actor_info_length DESC, keyword_count DESC;

