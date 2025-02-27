WITH RECURSIVE movie_hierarchy AS (
    SELECT m.id AS movie_id, 
           m.title, 
           m.production_year, 
           m.phonetic_code, 
           1 AS level 
    FROM aka_title m 
    WHERE m.production_year >= 2000
    
    UNION ALL
    
    SELECT t.movie_id, 
           t.title, 
           t.production_year, 
           t.phonetic_code, 
           mh.level + 1 
    FROM movie_link l 
    JOIN movie_hierarchy mh ON l.movie_id = mh.movie_id
    JOIN aka_title t ON l.linked_movie_id = t.id
)

SELECT 
    a.name AS actor_name,
    m.title AS movie_title,
    m.production_year,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
    COUNT(DISTINCT CAST(c.person_role_id AS INTEGER)) AS role_count
FROM movie_hierarchy m
JOIN cast_info c ON m.movie_id = c.movie_id
JOIN aka_name a ON c.person_id = a.person_id
LEFT JOIN movie_keyword mk ON m.movie_id = mk.movie_id
LEFT JOIN keyword kw ON mk.keyword_id = kw.id
WHERE 
    m.production_year >= 2000 
    AND a.name IS NOT NULL
    AND a.name <> ''
GROUP BY a.name, m.title, m.production_year
HAVING COUNT(DISTINCT c.id) > 1
ORDER BY m.production_year DESC, role_count DESC
LIMIT 100;

This SQL query accomplishes the following:

1. **Recursive CTE (`movie_hierarchy`)**: Generates a hierarchy of movies starting from those produced from the year 2000 onwards, making it useful for analyzing sequels or related films.

2. **Main Query**: Joins several tables (`cast_info`, `aka_name`, `movie_keyword`, and `keyword`) to gather information on actors, their movies, and associated keywords.

3. **Aggregate Functions**: Utilizes `STRING_AGG` to compile keywords associated with each movie, and `COUNT` to determine the number of distinct roles an actor has played.

4. **Filtering**: Applies predicates to ensure names are not null or empty, and only considers movies from 2000 onwards.

5. **Group and Order**: Groups by actor name and movie details to get a count of roles, then orders by production year and role count to prioritize more recent and prolific actors.

6. **Limit**: Limits the results to the top 100 entries to optimize performance and readability.

This structure showcases multiple SQL constructs that challenge the performance while ensuring a meaningful result set for benchmarking.
