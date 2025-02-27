WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
      
    UNION ALL
    
    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    ak.name AS actor_name,
    ct.kind AS company_type,
    GROUP_CONCAT(DISTINCT CONCAT(mh.title, ' (', mh.production_year, ')') ORDER BY mh.production_year DESC SEPARATOR ', ') AS movie_titles,
    COUNT(mh.movie_id) AS total_movies,
    AVG(CASE WHEN i.info IS NOT NULL THEN LENGTH(i.info) ELSE 0 END) AS avg_info_length,
    MIN(mh.production_year) AS first_movie_year
FROM 
    aka_name ak
LEFT JOIN 
    cast_info ci ON ak.person_id = ci.person_id
LEFT JOIN 
    MovieHierarchy mh ON ci.movie_id = mh.movie_id
LEFT JOIN 
    movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN 
    company_type ct ON mc.company_type_id = ct.id
LEFT JOIN 
    movie_info mi ON mh.movie_id = mi.movie_id
LEFT JOIN 
    info_type it ON mi.info_type_id = it.id
LEFT JOIN 
    person_info pi ON ak.person_id = pi.person_id
LEFT JOIN 
    (SELECT person_id, info, ROW_NUMBER() OVER (PARTITION BY person_id ORDER BY LENGTH(info) DESC) AS rn
     FROM person_info
     WHERE info IS NOT NULL) AS i ON ak.person_id = i.person_id AND i.rn = 1
WHERE 
    ak.name IS NOT NULL
GROUP BY 
    ak.name, ct.kind
HAVING 
    total_movies > 5 
    AND first_movie_year < (SELECT MAX(production_year) FROM aka_title WHERE kind_id = (SELECT id FROM kind_type WHERE kind = 'movie'))
ORDER BY 
    first_movie_year DESC, total_movies DESC;


### Explanation:

1. **Common Table Expression (CTE)**: The `MovieHierarchy` CTE is a recursive CTE that constructs a hierarchy of movies linked to one another through a self-referential link.

2. **Joins**: The main query uses several OUTER JOINs:
   - `LEFT JOIN` retrieves movies an actor has participated in, along with their companies and other related information.

3. **Group Functions**: 
   - `GROUP_CONCAT` aggregates movie titles per actor.
   - `AVG`, `COUNT`, and `MIN` are used to derive various metrics (average info length, total movies, and year of the first movie).

4. **Window Functions**: The subquery used to calculate row numbers (`ROW_NUMBER()`) allows for retrieving additional information based on the length of the info text.

5. **Complicated Predicates**: The `HAVING` clause uses intricate logic to filter based on total movies and production years, ensuring only the relevant actors with significant filmographies are included.

6. **Non-null checks**: Specifications ensure that we're not working with NULL names or info in the right places.

7. **Ordering**: Finally, results are ordered by the year of the first movie and the total number of movies each actor has participated in, showing the most established actors first.

This SQL query is constructed to benchmark performance effectively, showcasing the power and complexities of SQL capabilities against the model's defined schema.
