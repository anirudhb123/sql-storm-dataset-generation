WITH RECURSIVE MovieHierachy AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        m.id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        aka_title m
    INNER JOIN 
        movie_link ml ON ml.movie_id = m.id
    INNER JOIN 
        MovieHierachy mh ON mh.movie_id = ml.linked_movie_id
)
SELECT 
    a.name AS actor_name,
    m.movie_title,
    mh.level,
    COALESCE(ki.keyword, 'No Keywords') AS movie_keyword,
    COUNT(DISTINCT mc.company_id) AS production_companies,
    AVG(CASE 
        WHEN ci.role_id IS NOT NULL THEN ci.nr_order 
        ELSE NULL 
    END) AS avg_role_order,
    STRING_AGG(DISTINCT ci.note, ', ') AS role_notes,
    m.production_year
FROM 
    aka_name a
INNER JOIN 
    cast_info ci ON a.person_id = ci.person_id
INNER JOIN 
    MovieHierachy mh ON ci.movie_id = mh.movie_id
INNER JOIN 
    movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    keyword ki ON mk.keyword_id = ki.id
GROUP BY 
    a.name, m.movie_title, mh.level, m.production_year
HAVING 
    COUNT(DISTINCT mc.company_id) > 2 AND 
    m.production_year BETWEEN 2000 AND 2023
ORDER BY 
    mh.level DESC, avg_role_order ASC;

### Query Explanation:

1. **CTE (Recursive)**: The `MovieHierarchy` Common Table Expression fetches movies produced from 2000 onward and recursively joins to obtain linked movies, creating a hierarchy.

2. **Main Query**: 
   - **Joins**:
     - Join `aka_name` with `cast_info` to retrieve actor names.
     - Join the hierarchy from `MovieHierarchy` to get movie titles.
     - Join `movie_companies` to count associated companies.
     - Left join `movie_keyword` to potentially bring in keywords and handle cases where no keywords might exist using `COALESCE`.

3. **Aggregations**:
   - Averages the `nr_order` from `cast_info` to reflect actors' average role order.
   - Uses `STRING_AGG` to combine the notes related to roles.

4. **Grouping and Filtering**: Grouped by actor name, movie title, hierarchy level, and year; with a `HAVING` clause to filter for movies having more than two production companies and released within the specified year range.

5. **Ordering**: The results are ordered by level in descending order and average role order in ascending order for insight into actor involvement in various movie linkages.
