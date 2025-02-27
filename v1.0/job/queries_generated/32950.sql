WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        at.kind_id,
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
    at.title AS movie_title,
    at.production_year,
    mt.kind AS movie_kind,
    array_agg(DISTINCT kw.keyword) AS keywords,
    COUNT(DISTINCT cc.id) AS cast_count,
    AVG(mr.depth) AS avg_depth
FROM 
    cast_info cc
JOIN 
    aka_name ak ON cc.person_id = ak.person_id
JOIN 
    aka_title at ON cc.movie_id = at.id
LEFT JOIN 
    movie_keyword mk ON at.id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
LEFT JOIN 
    movie_hierarchy mr ON at.id = mr.movie_id
JOIN 
    kind_type mt ON at.kind_id = mt.id
WHERE 
    ak.name IS NOT NULL
    AND at.production_year >= 2000
    AND (kw.keyword IS NULL OR LENGTH(kw.keyword) > 3)
GROUP BY 
    ak.name, at.title, at.production_year, mt.kind
ORDER BY 
    avg_depth DESC, cast_count DESC
LIMIT 10;


In this query:
- A recursive CTE `movie_hierarchy` constructs a hierarchy of movies based on linked movies, counting their depth.
- The main query selects actor names, movie titles, production years, and movie kinds.
- It utilizes `LEFT JOIN` to pull in keywords and aggregates them into an array.
- It counts distinct cast members and calculates the average depth of the movie in the hierarchy.
- The `WHERE` clause has several conditions including NULL logic and string length checks on keywords.
- Finally, it orders the results by average depth and the count of cast members, limiting the output to the top 10.
