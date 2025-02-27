WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        0 AS level
    FROM 
        aka_title AS m
    WHERE 
        m.production_year IS NOT NULL

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        mt.title,
        mt.production_year,
        mh.level + 1
    FROM 
        movie_link AS ml
    JOIN 
        aka_title AS mt ON ml.linked_movie_id = mt.id
    JOIN 
        MovieHierarchy AS mh ON ml.movie_id = mh.movie_id
)

SELECT 
    a.name AS actor_name,
    COUNT(DISTINCT c.movie_id) AS movies_count,
    AVG(DATE_PART('year', CURRENT_DATE) - m.production_year) AS avg_movie_age,
    STRING_AGG(DISTINCT k.keyword, ', ') AS associated_keywords,
    MAX(mh.level) AS max_hierarchy_level
FROM 
    aka_name AS a
JOIN 
    cast_info AS c ON a.person_id = c.person_id
JOIN 
    aka_title AS m ON c.movie_id = m.id
LEFT JOIN 
    movie_keyword AS mk ON m.id = mk.movie_id
LEFT JOIN 
    keyword AS k ON mk.keyword_id = k.id
LEFT JOIN 
    MovieHierarchy AS mh ON m.id = mh.movie_id
WHERE 
    a.name IS NOT NULL
    AND m.production_year >= 1990
GROUP BY 
    a.name
HAVING 
    COUNT(DISTINCT c.movie_id) > 5
ORDER BY 
    avg_movie_age DESC, movies_count DESC;

### Explanation:
1. **Common Table Expression (CTE)**: A recursive CTE named `MovieHierarchy` is created to build a hierarchy of linked movies.
2. **Aggregations**: The main SELECT retrieves actor names and aggregates:
   - Count of distinct movies they appeared in.
   - Average age of the movies based on the current year and production year.
   - A set of associated keywords for each actor.
   - Maximum hierarchy level of linked movies.
3. **Joins**: Multiple JOIN statements are used to bring together data from several tables, including outer joins to capture all related keywords.
4. **Predicate Logic**: Conditions filter out actors with null names and to include movies released from 1990 onward.
5. **Grouping and Having**: The results are grouped by actor name with a HAVING clause filtering for actors involved in more than 5 movies.
6. **Ordering**: Final results are ordered by average movie age and movie count.
