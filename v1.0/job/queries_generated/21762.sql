WITH RecursiveMovieHierarchy AS (
    SELECT 
        mt.id AS movie_id, 
        mt.title, 
        mt.production_year, 
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        m.id AS movie_id, 
        m.title, 
        m.production_year, 
        mh.depth + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
    JOIN 
        RecursiveMovieHierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    a.name AS actor_name,
    COUNT(DISTINCT c.movie_id) AS movie_count,
    STRING_AGG(DISTINCT t.title, ', ') AS titles,
    (SELECT COUNT(DISTINCT k.keyword) 
     FROM movie_keyword mk
     JOIN keyword k ON mk.keyword_id = k.id
     WHERE mk.movie_id IN (SELECT movie_id FROM cast_info ci WHERE ci.person_id = a.person_id)
    ) AS keyword_count,
    MAX(CASE WHEN mt.production_year = 2023 THEN 'Yes' ELSE 'No' END) AS made_2023,
    SUM(CASE WHEN c.role_id IS NOT NULL THEN 1 ELSE 0 END) AS cast_count
FROM 
    aka_name a
LEFT JOIN 
    cast_info c ON a.person_id = c.person_id
LEFT JOIN 
    RecursiveMovieHierarchy r ON c.movie_id = r.movie_id
LEFT JOIN 
    aka_title t ON c.movie_id = t.movie_id
WHERE 
    a.name IS NOT NULL 
    AND (a.surname_pcode IS NOT NULL OR a.name_pcode_cf IS NULL)
GROUP BY 
    a.name
HAVING 
    COUNT(DISTINCT c.movie_id) > 5
ORDER BY 
    movie_count DESC, actor_name ASC
LIMIT 10;

### Explanation:
1. **Common Table Expression (CTE)**: `RecursiveMovieHierarchy` builds a hierarchy of movies and linked movies up to any depth related to the main movie data.
2. **Select Statement**: 
   - Aggregates data per actor from the `aka_name`, `cast_info`, `aka_title`, and CTE for movie relationships.
   - Calculate counts of distinct movies and keywords associated with them.
   - Uses a conditional expression to check if any movies were produced in 2023.
   - Summarizes roles based on `cast_info`.
3. **WHERE Clause**: Filters out actors with NULL names or whose name conditions are satisfied, introducing some NULL logic.
4. **GROUP BY and HAVING**: Groups results by actor name and filters those with more than 5 distinct movies.
5. **ORDER BY and LIMIT**: Orders the results by the number of movies acted in, ensuring the top results are returned.
