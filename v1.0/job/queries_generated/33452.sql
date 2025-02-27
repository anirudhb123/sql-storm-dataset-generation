WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mp.name AS production_company
    FROM 
        aka_title mt
    JOIN 
        movie_companies mcp ON mt.id = mcp.movie_id
    JOIN 
        company_name mp ON mcp.company_id = mp.id
    WHERE 
        mt.production_year >= 2000
    UNION ALL
    SELECT 
        mt.id,
        mt.title,
        mt.production_year,
        mp.name
    FROM 
        aka_title mt
    JOIN 
        movie_link ml ON mt.id = ml.movie_id
    JOIN 
        movie_hierarchy mh ON mh.movie_id = ml.linked_movie_id
    JOIN 
        movie_companies mcp ON mh.movie_id = mcp.movie_id
    JOIN 
        company_name mp ON mcp.company_id = mp.id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    STRING_AGG(DISTINCT mh.production_company, ', ') AS production_companies,
    COUNT(ci.person_id) AS cast_count
FROM 
    movie_hierarchy mh
LEFT JOIN 
    cast_info ci ON mh.movie_id = ci.movie_id
GROUP BY 
    mh.movie_id, mh.title, mh.production_year
HAVING 
    COUNT(ci.person_id) > 5
ORDER BY 
    mh.production_year DESC;

### Explanation:
- **CTE (Common Table Expression):** The recursive CTE `movie_hierarchy` builds a hierarchy of movies from the `aka_title` table, beginning with movies produced from the year 2000 onwards. It pulls in production companies from the `company_name` table, joining on `movie_companies`.
- **Outer Join:** The outer join with `cast_info` ensures that we count all movies, even those without any cast listed, which will return NULL for `cast_count`.
- **String Aggregation:** `STRING_AGG()` collects distinct production companies for grouped results.
- **Count Aggregation:** We count the number of actors per movie and filter for movies with more than 5 cast members.
- **HAVING Clause:** This clause filters results after aggregation, ensuring only movies with considerable casts are displayed.
- **Order By Clause:** The results are ordered by the production year in descending order.
