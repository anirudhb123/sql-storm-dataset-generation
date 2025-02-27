WITH RECURSIVE MovieHierarchy AS (
    SELECT title.id AS movie_id,
           title.title,
           1 AS level,
           title.production_year
    FROM title
    WHERE title.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL

    SELECT mh.movie_id,
           t.title,
           mh.level + 1,
           t.production_year
    FROM MovieHierarchy mh
    JOIN movie_link ml ON mh.movie_id = ml.movie_id
    JOIN title t ON ml.linked_movie_id = t.id
    WHERE mh.level < 5  -- limiting the recursion depth
)

SELECT 
    ak.name AS actor_name,
    mt.title AS movie_title,
    mt.production_year AS year,
    COUNT(DISTINCT c.id) AS actor_count,
    SUM(CASE WHEN c.nr_order IS NOT NULL THEN 1 ELSE 0 END) AS credited_roles,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
    CASE 
        WHEN mt.production_year IS NULL THEN 'Unknown Year'
        ELSE CAST(mt.production_year AS text)
    END AS production_year_text,
    RANK() OVER (PARTITION BY mt.production_year ORDER BY COUNT(c.id) DESC) AS year_rank
FROM aka_name ak
LEFT JOIN cast_info c ON ak.person_id = c.person_id
LEFT JOIN aka_title at ON c.movie_id = at.movie_id
LEFT JOIN MovieHierarchy mh ON mh.movie_id = at.movie_id
LEFT JOIN movie_keyword mk ON at.movie_id = mk.movie_id
LEFT JOIN keyword kw ON mk.keyword_id = kw.id
LEFT JOIN title mt ON at.movie_id = mt.id
WHERE ak.name IS NOT NULL
GROUP BY ak.name, mt.title, mt.production_year
HAVING COUNT(DISTINCT c.id) > 1
ORDER BY year_rank, actor_name;

### Explanation:
- **Recursive CTE**: This builds a hierarchy of movies linked by the `movie_link` table, limiting the recursion depth to 5 levels to avoid excessive growth in complexity and time.
- **Outer Joins**: Used to ensure that we include all actors and movies even if there are missing relationships (e.g., an actor without a role).
- **Aggregation Functions**: The query counts distinct roles the actors played and sums credited roles. It also concatenates keywords associated with each movie.
- **CASE Statement**: It provides a fallback for production years that might be NULL.
- **Window Functions**: Ranks the movies by the number of actors in each production year.
- **Complex Grouping and Filtering**: Groups results by actor and movie, and filters to ensure only actors who have multiple roles appear.
- **String Aggregation**: Collects keywords into a comma-separated list for each movie.
- **HAVING clause**: Excludes actors who have played only one role to focus on more prolific performers.
