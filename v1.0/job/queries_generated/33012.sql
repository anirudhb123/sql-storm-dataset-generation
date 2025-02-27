WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        t.id AS movie_id, 
        t.title,
        t.production_year,
        1 AS depth
    FROM 
        aka_title t
    WHERE 
        t.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        mh.depth + 1 AS depth
    FROM 
        movie_link ml
    JOIN 
        aka_title t ON ml.linked_movie_id = t.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    a.name AS actor_name,
    m.title AS movie_title,
    m.production_year,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    COUNT(DISTINCT c.id) AS total_cast,
    AVG(pi.info IS NOT NULL)::numeric AS presence_ratio,
    ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY m.production_year DESC) AS movie_rank
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title m ON c.movie_id = m.id
LEFT JOIN 
    movie_keyword mk ON m.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    person_info pi ON a.person_id = pi.person_id AND pi.info_type_id = (SELECT id FROM info_type WHERE info = 'Biography')
WHERE 
    m.production_year >= 2000
    AND (a.name_pcode_cf IS NULL OR a.name_pcode_nf IS NOT NULL)
GROUP BY 
    a.id, m.id
HAVING 
    COUNT(DISTINCT c.id) > 5
ORDER BY 
    presence_ratio DESC,
    movie_rank ASC;

### Explanation of the Query Components:
1. **Common Table Expression (CTE)**: The `MovieHierarchy` CTE is a recursive query that builds a hierarchy of movies linked together, starting from base movies.

2. **SELECT Clause**: 
   - Retrieves actor names, movie titles, production years.
   - Aggregates keywords associated with movies into a single string.
   - Counts total cast members and calculates a presence ratio indicating the existence of biographical information.

3. **JOINs**: 
   - Multiple joins connect `aka_name`, `cast_info`, and `aka_title` to ensure all details about movies and cast are included, along with optional joins for keywords and person info.

4. **LEFT JOINs**: Handle cases where information might be missing without excluding entire records.

5. **WHERE Conditions**: 
   - Filters movies produced after 2000.
   - Includes logic for NULL handling on name postal codes.

6. **GROUP BY and HAVING**: Group by actor and movie IDs, filtering for actors with more than 5 distinct roles.

7. **Window Function**: Uses `ROW_NUMBER()` to rank movies per actor based on production year.

8. **ORDER BY Clause**: Orders the final result set by the presence ratio first, and then by movie rank.

The query is designed for complex benchmarking by pulling in various aspects of the data with performance considerations in mind.
