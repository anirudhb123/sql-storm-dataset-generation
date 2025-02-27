WITH RECURSIVE MovieHierarchy AS (
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
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        mh.level + 1
    FROM 
        aka_title m
    JOIN 
        movie_link ml ON m.id = ml.linked_movie_id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    mh.movie_id,
    mh.movie_title,
    mh.production_year,
    COUNT(DISTINCT ci.person_id) AS total_cast,
    AVG(CASE WHEN pi.info_type_id IS NOT NULL THEN 1 ELSE 0 END) AS avg_info_type_count,
    STRING_AGG(DISTINCT ak.name, ', ') AS aka_names
FROM 
    MovieHierarchy mh
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
LEFT JOIN 
    person_info pi ON ci.person_id = pi.person_id
LEFT JOIN 
    aka_name ak ON ci.person_id = ak.person_id
GROUP BY 
    mh.movie_id, mh.movie_title, mh.production_year
HAVING 
    AVG(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) > 0.5
ORDER BY 
    mh.production_year DESC, total_cast DESC;

### Explanation:
1. **Common Table Expression (CTE)**: 
   - `MovieHierarchy` is a recursive CTE that retrieves movies produced after 2000 and builds a hierarchy of movies based on links (i.e., sequels or related movies).

2. **Joins**:
   - Multiple LEFT JOINs are utilized to combine data from the `complete_cast`, `cast_info`, `person_info`, and `aka_name` tables, collecting information about casts, their roles, and alternative names.

3. **Aggregation**:
   - The query counts distinct cast members and averages the number of different info types associated with them while gathering aka names into a single string.

4. **HAVING**: 
   - The HAVING clause filters this aggregated data to only include movies where the average count of non-null notes per cast member exceeds 0.5, providing a qualifying threshold for completeness in casting information.

5. **Ordering**:
   - The results are ordered first by production year (most recent first) and then by the total cast count in descending order. 

This query is designed for performance benchmarking by combining various SQL constructs to analyze the relationships and data within a cinematic context.
