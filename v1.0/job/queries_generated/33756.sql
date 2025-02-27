WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        1 AS level
    FROM 
        aka_title a
    WHERE 
        a.kind_id IN (SELECT id FROM kind_type WHERE kind = 'feature');
    
    UNION ALL
    
    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        h.level + 1
    FROM 
        MovieHierarchy h
    JOIN 
        movie_link ml ON h.movie_id = ml.movie_id
    JOIN 
        aka_title m ON ml.linked_movie_id = m.movie_id
    WHERE 
        h.level < 5 -- To limit the depth of recursion
)

SELECT 
    h.movie_id,
    h.title,
    h.production_year,
    COALESCE(cast_count.cast_count, 0) AS total_cast,
    ARRAY_AGG(DISTINCT ak.name) AS aka_names,
    STRING_AGG(DISTINCT COALESCE(k.keyword, 'N/A'), ', ') AS keywords,
    SUM(CASE WHEN pi.note IS NOT NULL THEN 1 ELSE 0 END) AS person_info_count,
    ROW_NUMBER() OVER (PARTITION BY h.production_year ORDER BY h.title) AS row_num
FROM 
    MovieHierarchy h
LEFT JOIN 
    complete_cast cc ON h.movie_id = cc.movie_id
LEFT JOIN 
    (SELECT movie_id, COUNT(id) AS cast_count 
     FROM cast_info 
     GROUP BY movie_id) AS cast_count ON h.movie_id = cast_count.movie_id
LEFT JOIN 
    movie_keyword mk ON h.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    aka_title ak ON h.movie_id = ak.movie_id
LEFT JOIN 
    person_info pi ON ak.id = pi.person_id
GROUP BY 
    h.movie_id, h.title, h.production_year, cast_count.cast_count
HAVING 
    SUM(CASE WHEN pi.note IS NOT NULL THEN 1 ELSE 0 END) > 0
ORDER BY 
    h.production_year DESC, h.title;

### Explanation:
1. **Recursive CTE (MovieHierarchy)**: This part creates a hierarchy of movies linked together, allowing up to 5 levels (depth). It starts from feature films and recursively finds linked movies.
2. **Main Query**:
   - Joins the recursive CTE with other tables such as `complete_cast`, and aggregates to count the total number of cast members.
   - Uses `ARRAY_AGG` to gather distinct aka names associated with the title.
   - `STRING_AGG` aggregates keywords related to the movie, handling NULLs with `COALESCE`.
   - Counts `person_info` entries, employing conditional aggregation.
   - The use of **window function** (`ROW_NUMBER`) creates a unique row number for each movie within its respective year.
3. **NULL Logic**: Implements checks against NULLs and uses `COALESCE` for default values.
4. **Complicated Predicate**: In `HAVING`, it filters out movies with no associated person information. 

This query serves as a comprehensive performance benchmark, showcasing various SQL constructs and complexity.
