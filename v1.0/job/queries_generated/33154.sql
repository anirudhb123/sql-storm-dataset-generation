WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        0 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000  -- Targeting more recent films

    UNION ALL

    SELECT 
        m2.id AS movie_id,
        m2.title,
        m2.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title m2 ON ml.linked_movie_id = m2.id
)
SELECT 
    ak.name AS actor_name,
    mt.title AS movie_title,
    mt.production_year,
    COUNT(DISTINCT pt.id) AS distinct_cast_count,
    SUM(CASE WHEN m_comp.name IS NOT NULL THEN 1 ELSE 0 END) AS company_count,
    AVG(COALESCE(m_info.info::numeric, 0)) AS average_info_value
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    MovieHierarchy mt ON ci.movie_id = mt.movie_id
LEFT JOIN 
    movie_companies m_comp ON mt.movie_id = m_comp.movie_id
LEFT JOIN 
    movie_info m_info ON mt.movie_id = m_info.movie_id
WHERE 
    mt.level = 0  -- Only top-level movies
    AND ak.name IS NOT NULL
    AND m_info.info_type_id IN (SELECT id FROM info_type WHERE info LIKE '%Awards%')  -- Filter for awards info
GROUP BY 
    ak.name, mt.title, mt.production_year
HAVING 
    COUNT(DISTINCT pt.id) > 1  -- Movies with multiple cast members
ORDER BY 
    mt.production_year DESC, distinct_cast_count DESC;
This SQL query performs the following operations:

1. **Recursive CTE (Common Table Expression)**: `MovieHierarchy` is created to gather a nested structure of movies starting from those produced after 2000. It forms a hierarchy of the movies based on their linked relationships.
2. **JOIN Operations**: It joins multiple tables, including `aka_name`, `cast_info`, `movie_companies`, and `movie_info`, leveraging both inner and left joins.
3. **Aggregation Functions**: It counts distinct cast members, sums companies, and computes the average of numeric information types, applying `COALESCE` to handle NULLs in the average calculation.
4. **Filtering**: It uses a subquery in the WHERE clause to filter for specific types of information (like awards).
5. **GROUP BY and HAVING**: Aggregates data and applies conditions to filter for groups having more than one distinct cast member.
6. **Ordering**: Results are ordered by production year and distinct cast count.

This query will be useful for performance benchmarking, as it uses a complex structure with various SQL constructs and joins.
