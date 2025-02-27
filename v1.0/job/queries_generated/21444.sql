WITH RECURSIVE title_hierarchy AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.imdb_id,
        1 AS level,
        ARRAY[t.title] AS title_path
    FROM 
        aka_title t
    WHERE 
        t.season_nr IS NULL
    
    UNION ALL
    
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.imdb_id,
        th.level + 1 AS level,
        th.title_path || t.title
    FROM 
        aka_title t
    INNER JOIN 
        title_hierarchy th ON t.episode_of_id = th.title_id
)
SELECT 
    th.title,
    th.production_year,
    COUNT(DISTINCT cc.person_id) AS cast_count,
    STRING_AGG(DISTINCT ak.name, ', ') AS actor_names,
    MAX(CASE WHEN ki.keyword = 'Award' THEN 1 ELSE 0 END) AS has_award
FROM 
    title_hierarchy th
LEFT JOIN 
    complete_cast cc ON cc.movie_id = th.title_id
LEFT JOIN 
    cast_info ci ON ci.movie_id = th.title_id
LEFT JOIN 
    aka_name ak ON ak.person_id = ci.person_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = th.title_id
LEFT JOIN 
    keyword ki ON ki.id = mk.keyword_id
WHERE 
    th.production_year BETWEEN 2000 AND 2023
    AND th.level < 3 
GROUP BY 
    th.title, th.production_year
HAVING 
    COUNT(DISTINCT ci.person_id) > 2
ORDER BY 
    th.production_year DESC, cast_count DESC;

### Explanation:
1. **CTE `title_hierarchy`**: This recursively fetches titles and their hierarchy, enabling us to retrieve titles that are episodes of other titles while noting their levels in the hierarchy.

2. **Joins**:
    - `LEFT JOIN` with `complete_cast`, `cast_info`, and `aka_name` allows fetching details of cast members against the fetched titles.
    - `LEFT JOIN` with `movie_keyword` and `keyword` provides the ability to check whether a title has specific keywords, e.g., "Award."

3. **Filtering**:
   - The `WHERE` clause restricts titles to a particular production year range and limits the levels of the hierarchy being considered for the output.

4. **Aggregation**:
    - `COUNT(DISTINCT ci.person_id)` counts the unique actors in the cast.
    - `STRING_AGG(DISTINCT ak.name, ', ')` aggregates the names of actors into a single string.
    - Adding an obscure `MAX(CASE ...)` construct checks for the presence of a specific keyword.

5. **Having Clause**:
    - To ensure the result includes only titles with more than two cast members, the `HAVING` clause checks this condition.

6. **Ordering**:
    - Results are ordered by the production year descending and then by the number of cast members in descending order, providing a clear ranking of relevant titles.

This complex query utilizes various SQL constructs in a manner that not only benchmarks performance across joins and aggregations but also ensures the output is both informative and insightful.
