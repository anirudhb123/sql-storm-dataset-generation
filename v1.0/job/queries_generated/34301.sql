WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.depth + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    ak.name AS actor_name,
    mt.title AS movie_title,
    mh.production_year,
    COUNT(DISTINCT c.person_id) AS number_of_actors,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
    AVG(pi.info::NUMERIC) FILTER (WHERE pi.info_type_id = (SELECT id FROM info_type WHERE info = 'Rating')) AS avg_rating,
    ROW_NUMBER() OVER (PARTITION BY mt.kind_id ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
FROM 
    MovieHierarchy mh
JOIN 
    cast_info c ON mh.movie_id = c.movie_id
JOIN 
    aka_name ak ON c.person_id = ak.person_id
JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
JOIN 
    keyword kw ON mk.keyword_id = kw.id
JOIN 
    title mt ON mh.movie_id = mt.id
LEFT JOIN 
    person_info pi ON c.person_id = pi.person_id
WHERE 
    mh.depth <= 2 AND
    ak.name IS NOT NULL AND
    mt.production_year IS NOT NULL
GROUP BY 
    ak.name, mt.title, mh.production_year
HAVING 
    COUNT(DISTINCT c.person_id) > 0
ORDER BY 
    avg_rating DESC NULLS LAST,
    number_of_actors DESC
LIMIT 50;
