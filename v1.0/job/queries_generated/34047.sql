WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        m.title,
        m.production_year,
        mh.depth + 1
    FROM 
        movie_link ml
    JOIN 
        title m ON ml.linked_movie_id = m.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    ak.name AS actor_name,
    mt.movie_title,
    mh.depth,
    mt.production_year,
    COUNT(DISTINCT mc.company_id) AS num_production_companies,
    SUM(CASE 
            WHEN person.gender = 'F' THEN 1 
            ELSE 0 
        END) AS female_actors,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords
FROM 
    aka_name ak
JOIN 
    cast_info c ON ak.person_id = c.person_id
JOIN 
    movie_companies mc ON c.movie_id = mc.movie_id
JOIN 
    aka_title mt ON c.movie_id = mt.movie_id
LEFT JOIN 
    movie_keyword mw ON mt.id = mw.movie_id
LEFT JOIN 
    keyword kw ON mw.keyword_id = kw.id
LEFT JOIN 
    name person ON ak.person_id = person.imdb_id
LEFT JOIN 
    MovieHierarchy mh ON mt.id = mh.movie_id
WHERE 
    mt.production_year >= 2000 
    AND mt.kind_id IN (
        SELECT id FROM kind_type WHERE kind IN ('feature', 'tv movie')
    )
GROUP BY 
    ak.name, mt.movie_title, mh.depth, mt.production_year
ORDER BY 
    depth DESC, num_production_companies DESC;
