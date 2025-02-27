WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        1 AS level
    FROM 
        aka_title t
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')

    UNION ALL

    SELECT 
        m.linked_movie_id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title t ON ml.linked_movie_id = t.id
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
)

SELECT 
    a.name AS actor_name,
    m.movie_title,
    m.production_year,
    COALESCE((SELECT COUNT(*) FROM cast_info ci WHERE ci.movie_id = m.movie_id AND ci.person_id IN 
        (SELECT person_id FROM aka_name WHERE name = a.name)), 0) AS actor_movie_count,
    COUNT(DISTINCT mc.company_id) AS production_company_count,
    STRING_AGG(DISTINCT co.name, ', ') AS companies_involved,
    ROW_NUMBER() OVER (PARTITION BY m.movie_id ORDER BY m.production_year DESC) AS movie_rank
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    MovieHierarchy m ON ci.movie_id = m.movie_id
LEFT JOIN 
    movie_companies mc ON m.movie_id = mc.movie_id
LEFT JOIN 
    company_name co ON mc.company_id = co.id
WHERE 
    a.name IS NOT NULL
    AND m.production_year >= 2000
GROUP BY 
    a.name, m.movie_title, m.production_year
HAVING 
    COUNT(DISTINCT mc.company_id) > 1
ORDER BY 
    m.production_year DESC, actor_name;

### Explanation:
1. **Recursive CTE** (`MovieHierarchy`): This part of the query builds a hierarchy of movies based on direct links between them, enabling depth-first traversal of sequels or related movies. 

2. **Main SELECT Query**:
   - Joins with `aka_name`, `cast_info`, and the recursive `MovieHierarchy` to get movie and actor details.
   - Uses `LEFT JOIN` to include production company details, counting how many companies worked on each movie and aggregating their names.
   - Filters for movies released after 2000 with at least 2 production companies.

3. **Aggregate Functions**:
   - `COUNT(*)` to count actors' appearances in movies.
   - `STRING_AGG` to concatenate the names of production companies involved.

4. **Window Function**: The use of `ROW_NUMBER()` to assign rank to movies per actor based on their production year.

5. **Complicated Conditions**: The query checks for `NULL` values in name fields and filters for valid production years.

This SQL query is designed to explore actor involvement in movies while capturing the complexity of relationships and ensuring performance across large datasets.
