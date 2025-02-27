WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        1 AS level,
        mt.id AS root_id
    FROM aka_title mt
    WHERE mt.production_year >= 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        at.kind_id,
        mh.level + 1 AS level,
        mh.root_id
    FROM MovieHierarchy mh
    JOIN movie_link ml ON mh.movie_id = ml.movie_id
    JOIN aka_title at ON ml.linked_movie_id = at.id
)
SELECT 
    mh.root_id,
    mh.title AS root_title,
    mh.production_year AS root_year,
    COUNT(DISTINCT mh.movie_id) AS linked_count,
    AVG(mh.level) AS avg_link_level
FROM MovieHierarchy mh
JOIN complete_cast cc ON mh.movie_id = cc.movie_id
JOIN cast_info ci ON cc.subject_id = ci.person_id
LEFT JOIN aka_name an ON ci.person_id = an.person_id AND an.name IS NOT NULL
LEFT JOIN movie_info mi ON mh.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Genres' LIMIT 1)
WHERE 
    mh.production_year IS NOT NULL 
    AND (mi.info IS NULL OR mi.info NOT LIKE '%Documentary%')
GROUP BY mh.root_id, mh.title, mh.production_year
HAVING COUNT(DISTINCT ci.person_id) > 10
ORDER BY avg_link_level DESC, linked_count DESC
LIMIT 100;

### Explanation:
1. **Recursive CTE (`MovieHierarchy`)**: This portion of the query generates a hierarchy of movies linked together via the `movie_link` table, starting with movies produced from the year 2000 onward.

2. **Outer Joins**: The query uses `LEFT JOIN` to include movies that may not have associated genre information (`movie_info`).

3. **Aggregations**: The query counts distinct linked movies (using `COUNT(DISTINCT mh.movie_id)`) and calculates the average level of links for each movie in the hierarchy (`AVG(mh.level)`).

4. **Complicated predicates**: It checks for non-null production years. It also filters out movies that are documented films by checking for genres that do not contain "Documentary".

5. **HAVING Clause**: The query ensures that only movies linked to more than 10 distinct cast members are returned.

6. **Ordering and Limiting**: The results are ordered by the average link level in descending order and the count of linked movies. Finally, it limits the results to the top 100 entries. 

This query is designed for performance benchmarking by meshing multiple SQL functionalities and joins to evaluate execution time efficiently while maintaining comprehensiveness in data representation.
