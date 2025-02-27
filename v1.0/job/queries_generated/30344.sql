WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        0 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000 -- consider movies from the year 2000 and onwards

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        mt.title,
        mt.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    mk.keyword,
    COUNT(DISTINCT m.movie_id) AS movie_count,
    AVG(mh.production_year) AS avg_production_year,
    STRING_AGG(DISTINCT CONCAT(a.name, ' as ', r.role)) AS all_cast
FROM 
    movie_keyword mk
JOIN 
    aka_title m ON mk.movie_id = m.movie_id
LEFT JOIN 
    movie_companies mc ON mc.movie_id = m.id
LEFT JOIN 
    company_name c ON mc.company_id = c.id
LEFT JOIN 
    cast_info ci ON ci.movie_id = m.id
LEFT JOIN 
    role_type r ON ci.role_id = r.id
LEFT JOIN 
    aka_name a ON ci.person_id = a.person_id
LEFT JOIN 
    MovieHierarchy mh ON m.id = mh.movie_id
WHERE 
    mk.keyword IS NOT NULL 
    AND m.production_year >= 2010 
    AND (c.country_code IS NULL OR c.country_code = 'USA') -- Filter for companies based in the USA
GROUP BY 
    mk.keyword
HAVING 
    COUNT(DISTINCT m.movie_id) > 1 -- Only keep keywords associated with more than one movie
ORDER BY 
    movie_count DESC;

This query does the following:

1. **Recursive CTE**: It starts with movies from the year 2000 onward and builds a hierarchy of linked movies.
2. **Keyword Association**: It counts distinct movies associated with each keyword, filtering by both production year and country code.
3. **Average Production Year**: It computes the average production year of the movies for each keyword.
4. **String Aggregation**: It concatenates the cast members' names along with their roles for all the movies associated with each keyword.
5. **HAVING Clause**: Filters keywords that are associated with more than one movie.
6. **Order By**: Results are ordered by the number of movies descending. 

This complex SQL query demonstrates various useful constructs, including CTEs, joins, window functions, string manipulation, and filtering logic.
