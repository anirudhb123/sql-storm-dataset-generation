WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        NULL::integer AS parent_movie_id,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year > 2000

    UNION ALL
    
    SELECT 
        ml.linked_movie_id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        mh.movie_id AS parent_movie_id,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
    WHERE 
        mt.production_year > 2000
)
SELECT 
    mh.movie_id,
    mh.movie_title,
    mh.production_year,
    mh.parent_movie_id,
    mh.level,
    COUNT(ci.person_id) AS actor_count,
    STRING_AGG(DISTINCT ak.name, ', ') AS actor_names,
    AVG(mi.info) AS avg_movie_info_length
FROM 
    MovieHierarchy mh
LEFT JOIN 
    cast_info ci ON mh.movie_id = ci.movie_id
LEFT JOIN 
    aka_name ak ON ci.person_id = ak.person_id
LEFT JOIN 
    movie_info mi ON mh.movie_id = mi.movie_id
WHERE 
    mh.level <= 2
    AND ak.name IS NOT NULL
GROUP BY 
    mh.movie_id, mh.movie_title, mh.production_year, mh.parent_movie_id, mh.level
HAVING 
    COUNT(ci.person_id) > 0
ORDER BY 
    mh.production_year DESC, 
    actor_count DESC
LIMIT 50;

**Explanation:**
1. A recursive CTE (`MovieHierarchy`) is used to create a hierarchy of movies from the `aka_title` table, focusing on movies produced after 2000. It also tracks the level of each movie in the hierarchy.
2. The main query selects from this CTE, joining to various tables:
   - `cast_info` to count actors and retrieve their names.
   - `movie_info` to calculate the average length of movie info based on relevant movie entries.
3. The results are filtered such that each movie must have at least one associated actor (`HAVING COUNT(ci.person_id) > 0`), and the level in the hierarchy is limited to the first two levels.
4. The results are ordered by production year (most recent first) and actor count (highest count first).
5. A limit is set to return only the top 50 results.
