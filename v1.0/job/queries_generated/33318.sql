WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        1 AS level,
        ARRAY[mt.id] AS path
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        at.title,
        mh.level + 1,
        path || ml.linked_movie_id
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    WHERE 
        ml.link_type_id = (SELECT id FROM link_type WHERE link = 'sequel') 
        AND not (ml.linked_movie_id = ANY(mh.path))
)

SELECT 
    a.name AS actor_name,
    m.title AS movie_title,
    COUNT(DISTINCT ch.id) AS character_count,
    MAX(m.production_year) AS latest_year,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
    SUM(CASE 
        WHEN mp.note IS NOT NULL THEN 1 
        ELSE 0 
    END) AS company_count, 
    RANK() OVER (PARTITION BY a.id ORDER BY COUNT(DISTINCT ch.id) DESC) AS rank
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title m ON c.movie_id = m.id
LEFT JOIN 
    char_name ch ON ch.imdb_index = m.imdb_index
LEFT JOIN 
    movie_companies mp ON mp.movie_id = m.id
LEFT JOIN 
    movie_keyword mw ON mw.movie_id = m.id
LEFT JOIN 
    keyword kw ON mw.keyword_id = kw.id
JOIN 
    MovieHierarchy mh ON mh.movie_id = m.id
WHERE 
    mh.level <= 3
GROUP BY 
    a.id, m.id
HAVING 
    COUNT(DISTINCT ch.id) > 1 
ORDER BY 
    rank;

This SQL query:
1. Defines a recursive CTE `MovieHierarchy` to traverse a hierarchy of linked movies starting from those produced after 2000.
2. Joins multiple tables including `cast_info`, `aka_title`, `char_name`, `movie_companies`, and `keyword` to gather detailed information about actors and movies.
3. Uses aggregate functions to count characters, sum conditions based on company notes, and aggregate keywords.
4. Applies a window function for ranking actors based on the number of distinct characters they portrayed.
5. Employs various join types, including left joins, to include all relevant data while allowing for NULL records.
6. Filters the results for movies with more than one character and limits the movie hierarchy depth to 3.
7. Orders the final output by actor rank.
