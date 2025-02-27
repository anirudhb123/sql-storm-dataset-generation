WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COALESCE(mo.linked_movie_id, 0) AS linked_movie_id,
        1 AS level
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_link mo ON mt.id = mo.movie_id
    WHERE 
        mt.production_year >= 2000 -- Filter for newer movies
    
    UNION ALL
    
    SELECT 
        mt.id,
        mt.title,
        mt.production_year,
        mo.linked_movie_id,
        mh.level + 1
    FROM 
        movie_hierarchy mh
    JOIN 
        movie_link mo ON mh.movie_id = mo.movie_id
    JOIN 
        aka_title mt ON mo.linked_movie_id = mt.id
)
SELECT 
    ak.name,
    mt.title AS movie_title,
    mt.production_year,
    CASE 
        WHEN ak.name IS NULL THEN 'Unknown Actor' 
        ELSE ak.name 
    END AS actor_name,
    COUNT(mh.linked_movie_id) AS linked_movies,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
    RANK() OVER (PARTITION BY mt.production_year ORDER BY COUNT(mh.linked_movie_id) DESC) AS movie_rank,
    COALESCE(STRING_AGG(DISTINCT ci.note, '; '), 'No Notes') AS cast_notes
FROM 
    movie_hierarchy mh
JOIN 
    cast_info ci ON mh.movie_id = ci.movie_id
JOIN 
    aka_name ak ON ci.person_id = ak.person_id
JOIN 
    aka_title mt ON mh.movie_id = mt.id
LEFT JOIN 
    movie_keyword mk ON mt.id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
GROUP BY 
    ak.name, mt.title, mt.production_year
HAVING 
    linked_movies > 0 AND mt.production_year IS NOT NULL
ORDER BY 
    movie_rank, mt.production_year DESC;

This query demonstrates several advanced SQL features, including:
- A recursive common table expression (CTE) to explore movie links and build a hierarchy.
- Use of window functions (`RANK()`) to rank movies based on the number of linked movies.
- Joining multiple tables (including outer joins) and aggregating results with functions like `STRING_AGG`.
- Handling NULL values with `COALESCE` and CASE expressions. 
- Filters and predicates to refine the dataset based on criteria such as the production year.
