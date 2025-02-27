WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year = (SELECT MAX(production_year) FROM aka_title)

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
    a.name AS actor_name,
    mt.title AS movie_title,
    mt.production_year,
    coalesce(AVG(CASE WHEN ci.role_id IS NOT NULL THEN 1 ELSE 0 END), 0) AS avg_lead_role,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    COUNT(DISTINCT mc.company_id) AS production_companies,
    COUNT(DISTINCT ci.person_id) AS total_cast,
    ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.title) AS year_rank
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    aka_title mt ON ci.movie_id = mt.id
LEFT JOIN 
    movie_keyword mk ON mt.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_companies mc ON mt.id = mc.movie_id
WHERE 
    a.name IS NOT NULL
    AND mt.production_year BETWEEN 2000 AND 2023 
GROUP BY 
    a.name, mt.title, mt.production_year
HAVING 
    COUNT(DISTINCT ci.person_id) > 5
ORDER BY 
    mt.production_year DESC, a.name
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;

### Explanation of the SQL Query Components
1. **Recursive CTE (`MovieHierarchy`)**:
   - This CTE builds a hierarchy of movies starting from the most recent production year, linking movies based on their relationships in the `movie_link` table.

2. **SELECT Statement**:
   - It selects the actor's name, associated movie titles, production years, and computes various aggregates (average lead roles, keywords, count of production companies and total cast).
   
3. **Joins**:
   - Involves multiple joins to the `cast_info`, `aka_title`, `movie_keyword`, `keyword`, and `movie_companies` tables to gather comprehensive data about actors and movies.

4. **NULL Handling with `COALESCE`**:
   - Utilizes `COALESCE` to replace `NULL` with 0 for the average lead role calculation.

5. **String Aggregation**:
   - Uses `STRING_AGG` to concatenate multiple keywords associated with each movie.

6. **Window Function (`ROW_NUMBER`)**:
   - Assigns ranks to movies within the same production year based on the title.

7. **Filtering via `HAVING`**:
   - Filters results to include only actors who performed in more than 5 movies.

8. **Ordering and Pagination**:
   - Results are sorted by descending production year and actor name, with pagination for limiting output to the first ten results.

This query effectively showcases a variety of complex SQL features while providing meaningful insights into the relationships and statistics in a movie database.
