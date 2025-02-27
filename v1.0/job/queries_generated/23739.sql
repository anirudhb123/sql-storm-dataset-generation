WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        0 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        at.kind_id,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    ak.name AS actor_name,
    title.title AS movie_title,
    title.production_year,
    COUNT(DISTINCT mp.company_id) AS number_of_production_companies,
    COUNT(DISTINCT mk.keyword) AS keyword_count,
    STRING_AGG(DISTINCT mk.keyword, ', ') AS all_keywords,
    MAX(CASE WHEN p.gender = 'F' THEN 'Female' ELSE 'Male' END) AS predominant_gender,
    ROW_NUMBER() OVER (PARTITION BY ak.name ORDER BY title.production_year DESC) AS movie_rank
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    movie_hierarchy title ON ci.movie_id = title.movie_id
LEFT JOIN 
    movie_companies mp ON mp.movie_id = title.movie_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = title.movie_id
JOIN 
    name p ON ak.id = p.id
WHERE 
    ak.name IS NOT NULL 
    AND (title.production_year > 2000 OR title.kind_id NOT IN (SELECT id FROM kind_type WHERE kind LIKE 'Documentary'))
    AND (mp.company_id IS NULL OR mp.note IS NOT NULL)
GROUP BY 
    ak.name, title.title, title.production_year
HAVING 
    COUNT(DISTINCT mp.company_id) > 0 
ORDER BY 
    movie_rank, number_of_production_companies DESC NULLS LAST
OFFSET 10 ROWS FETCH NEXT 20 ROWS ONLY;

### Explanation of Constructs Used:
1. **CTE (Common Table Expression)**: `movie_hierarchy` is used to recursively gather data about movie links, creating a hierarchy starting from movies with a defined production year.

2. **Outer Joins**: Leverage `LEFT JOIN` for potential relationships with production companies and keywords to include all necessary details even if some relationships are missing.

3. **Window Functions**: The `ROW_NUMBER()` function is used to rank movies based on their production year for each actor, which helps in organizing the output.

4. **Aggregate Functions**: `COUNT(DISTINCT ...)` is used to calculate unique counts of production companies and keywords, and `STRING_AGG` is used to compile a list of keywords for each movie.

5. **Case Expressions**: Used to determine the predominant gender of actors, ensuring it defaults to 'Male' when there’s no female gender entry.

6. **Complicated Predicates**: Filters include non-null names, production year checks, and company conditions that involve both `NULL` checks and conditions on the `note` column.

7. **Set Operators**: A subquery within the WHERE clause is used to exclude certain `kind_id` entries from the filtering.

8. **NULL Logic**: Used in `HAVING` to ensure results only include actors who have worked in movies with associated production companies.

9. **Pagination**: The `OFFSET` and `FETCH` clauses are employed to paginate the results, limiting output for performance benchmarking. 

This query is intricate and highlights a mix of SQL features while adhering to the schema provided.
