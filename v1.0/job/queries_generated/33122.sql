WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id, 
        mt.title,
        mt.production_year,
        mt.kind_id,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000  -- Filtering for movies from the year 2000 onwards

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        at.kind_id,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        MovieHierarchy mh ON mh.movie_id = ml.movie_id
)
SELECT 
    mh.title,
    mh.production_year,
    k.keyword AS keyword,
    COUNT(DISTINCT c.person_id) AS cast_count,
    AVG(CASE WHEN pi.info IS NOT NULL THEN 1 ELSE 0 END) AS avg_has_person_info,
    STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
    ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rn
FROM 
    MovieHierarchy mh
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info c ON cc.subject_id = c.person_id 
LEFT JOIN 
    movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    person_info pi ON c.person_id = pi.person_id
WHERE 
    mh.level <= 2  -- Limit to direct and one level of linked movies
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, k.keyword
HAVING 
    COUNT(DISTINCT c.person_id) > 1  -- Select movies with more than one cast member
ORDER BY 
    mh.production_year DESC,
    cast_count DESC;

This SQL query builds upon the provided schema and incorporates several advanced SQL features:

1. **Recursive CTE**: Used to construct a hierarchy of movies and their linked movies.
2. **Outer Joins**: Used to collect data even if there are no cast members or companies for some movies.
3. **Aggregations**: Counting cast members and averaging the presence of person info while avoiding NULLs with conditional aggregation.
4. **String Aggregation**: Collecting company names into a single string.
5. **Window Functions**: Calculating the rank of movies within each production year based on the number of cast members.
6. **Complicated Filtering**: Selecting only movies from 2000 onwards and limiting the hierarchy level.

This query serves as a performance benchmark by incorporating multiple operations and data retrieval techniques.
