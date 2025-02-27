WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id, 
        mt.title AS movie_title, 
        mt.production_year, 
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id, 
        a.title AS movie_title, 
        a.production_year, 
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title a ON ml.linked_movie_id = a.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    ah.name AS actor_name,
    mh.movie_title,
    mh.production_year,
    COUNT(DISTINCT mc.company_id) AS company_count,
    SUM(CASE WHEN aws.note IS NOT NULL THEN 1 ELSE 0 END) AS notable_roles,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
    RANK() OVER (PARTITION BY mh.production_year ORDER BY COUNT(DISTINCT mc.company_id) DESC) AS rank_by_company_count
FROM 
    MovieHierarchy mh
JOIN 
    complete_cast cc ON cc.movie_id = mh.movie_id
JOIN 
    aka_name ah ON cc.subject_id = ah.person_id
LEFT JOIN 
    movie_companies mc ON mc.movie_id = mh.movie_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = mh.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
LEFT JOIN 
    (SELECT 
        person_id, 
        note
    FROM 
        cast_info 
    WHERE 
        person_role_id IS NOT NULL) aws ON aws.person_id = ah.person_id
GROUP BY 
    ah.name, mh.movie_title, mh.production_year
HAVING 
    COUNT(DISTINCT mc.company_id) > 0 
ORDER BY 
    mh.production_year DESC, rank_by_company_count
LIMIT 100;

### Explanation of the Query Components:
1. **CTE (Common Table Expressions)**: 
   - `MovieHierarchy` recursively retrieves movies and their linked movies, creating a hierarchical structure.
   
2. **Joins**:
   - Utilizes outer and inner joins to gather information about actors, companies, roles, and keywords related to movies.

3. **Aggregations**:
   - `COUNT` and `SUM` are used to calculate the number of companies associated with each movie and notable roles for actors.

4. **String Aggregation**:
   - `STRING_AGG` is used to concatenate keywords associated with each movie into a single string for easier readability.

5. **Window Functions**:
   - `RANK()` assigned ranks to films based on the count of associated companies within each production year.

6. **HAVING Clause**:
   - Ensures that only movies with at least one associated company are returned.

7. **LIMIT**:
   - Restricts the output results to a maximum of 100 records.

8. **NULL Logic**:
   - The use of `CASE` expressions to count roles effectively handles potential NULL values in the `note` field.

This query can effectively benchmark performance by analyzing how well the database handles complex operations in terms of recursive relationships, aggregates, and dynamic data aggregation.
