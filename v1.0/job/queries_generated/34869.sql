WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        1 AS level
    FROM 
        aka_title AS m
    WHERE 
        m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        m.id AS movie_id,
        CONCAT(ph.title, ' -> ', m.title) AS title,
        mh.level + 1
    FROM 
        movie_link AS ml
    JOIN 
        aka_title AS m ON ml.linked_movie_id = m.id
    JOIN 
        MovieHierarchy AS mh ON ml.movie_id = mh.movie_id
)
SELECT 
    a.name AS actor_name,
    m.title AS movie_title,
    m.level,
    COUNT(cm.id) AS company_count,
    DENSE_RANK() OVER(ORDER BY m.level DESC) AS movie_rank,
    ARRAY_AGG(k.keyword) AS keywords
FROM 
    aka_name AS a
JOIN 
    cast_info AS c ON a.person_id = c.person_id
JOIN 
    aka_title AS m ON c.movie_id = m.movie_id
LEFT JOIN 
    movie_companies AS mc ON m.id = mc.movie_id
LEFT JOIN 
    company_name AS cn ON mc.company_id = cn.id
LEFT JOIN 
    movie_keyword AS mk ON m.id = mk.movie_id
LEFT JOIN 
    keyword AS k ON mk.keyword_id = k.id
WHERE 
    m.production_year >= 2000
    AND a.name IS NOT NULL
GROUP BY 
    a.name, m.title, m.level
HAVING 
    COUNT(mc.id) > 1
ORDER BY 
    movie_rank, a.name;

### Explanation:
1. **Recursive CTE (Common Table Expression)**: The `MovieHierarchy` CTE recursively builds a hierarchy of movies, assuming some movies are linked to others, creating a chain of related movies.

2. **Main Query**: This aggregates data about actors, filtering movies from the year 2000 onwards.

3. **Joins**:
   - Joins actors (`aka_name`) with their roles (`cast_info`) and the corresponding movies (`aka_title`).
   - Companies linked to each movie are tallied, allowing for a count of associated companies.
   - Keywords associated with movies are aggregated into an array.

4. **Window Function**: A `DENSE_RANK()` is applied to give each movie a rank based on its level in the hierarchy.

5. **Group by and Having**: Results are grouped by actor name, movie title, and hierarchy level, with a filter to include only those movies that have more than one associated company.

6. **Final Output**: The result includes actor names, movie titles, hierarchy level, company count, movie rank, and the list of keywords, ordered by movie rank and actor name.
