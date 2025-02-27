WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        at.title,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    ak.name AS actor_name,
    mt.title AS movie_title,
    mb.production_year,
    COALESCE(NULLIF(person_info.info, ''), 'No additional info') AS info,
    COUNT(DISTINCT kc.keyword) AS keyword_count,
    ROW_NUMBER() OVER (PARTITION BY ak.person_id ORDER BY mb.production_year DESC) AS rank,
    STRING_AGG(DISTINCT kc.keyword, ', ') AS keywords_list
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    movie_hierarchy mh ON ci.movie_id = mh.movie_id
JOIN 
    aka_title mt ON mh.movie_id = mt.id
JOIN 
    movie_keyword mk ON mt.id = mk.movie_id
JOIN 
    keyword kc ON mk.keyword_id = kc.id
LEFT JOIN 
    person_info ON ak.person_id = person_info.person_id
LEFT JOIN 
    movie_info mb ON mb.movie_id = mt.id AND mb.info_type_id = (
        SELECT id FROM info_type WHERE info = 'Production Year'
    )
WHERE 
    ak.name IS NOT NULL
    AND (ci.note IS NULL OR ci.note != 'Extra')
GROUP BY 
    ak.name, mt.title, mb.production_year, person_info.info
HAVING 
    COUNT(DISTINCT kc.keyword) > 0
ORDER BY 
    ak.name, mb.production_year DESC;

This query performs the following actions:

1. **Recursive CTE `movie_hierarchy`:** Retrieves movies produced from the year 2000 onward and links any related movies through the `movie_link` table, creating a hierarchy of movies.
2. **Main SELECT statement:** 
   - Selects actor names from `aka_name`.
   - Joins across multiple tables to gather information about the movies they were in, the production year, and any associated keywords.
3. **COALESCE and NULL handling:** Uses `COALESCE` to provide a fallback message if a person's info is missing or empty.
4. **Window Function:** Assigns a ranking to each actor's movies by production year.
5. **STRING_AGG:** Constructs a comma-separated list of keywords associated with each movie.
6. **Filtering:** Ensures that only actors with non-null names and no 'extra' notes in `cast_info` are included.
7. **Aggregation and HAVING clause:** Groups the results to get counts of distinct keywords associated with movies and filters out those who have no keywords.

This query tests performance through its complexity and various SQL constructs, including outer joins, CTEs, aggregations, and window functions.
