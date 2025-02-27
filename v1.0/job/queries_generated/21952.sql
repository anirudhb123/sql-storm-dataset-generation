WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000
    UNION ALL
    SELECT 
        ml.linked_movie_id,
        mt.title,
        mt.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title mt ON mt.id = ml.linked_movie_id
    WHERE 
        mh.level < 5  -- limit depth of recursion
)
SELECT 
    ak.name AS actor_name,
    at.title AS movie_title,
    at.production_year,
    COUNT(CASE WHEN mi.info_type_id = 1 THEN 1 END) AS info_count,
    AVG(mk.popularity_score) AS avg_popularity, -- assumes a hypothetical popularity score
    STRING_AGG(DISTINCT co.name, ', ') AS companies_involved,
    ROW_NUMBER() OVER (PARTITION BY ak.name ORDER BY at.production_year DESC) AS movie_rank,
    ARRAY_AGG(DISTINCT kt.keyword) AS keywords
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    aka_title at ON ci.movie_id = at.id
LEFT JOIN 
    movie_companies mc ON at.id = mc.movie_id
LEFT JOIN 
    company_name co ON mc.company_id = co.id
LEFT JOIN 
    movie_keyword mk ON at.id = mk.movie_id
LEFT JOIN 
    keyword kt ON mk.keyword_id = kt.id
LEFT JOIN 
    movie_info mi ON mi.movie_id = at.id
WHERE 
    ak.name IS NOT NULL
    AND (at.production_year BETWEEN 2000 AND 2023 OR at.production_year IS NULL)
GROUP BY 
    ak.name, at.id, at.title, at.production_year
HAVING 
    COUNT(DISTINCT ci.role_id) > 0
ORDER BY 
    movie_rank, actor_name;

This SQL query performs the following tasks:

1. **Recursive CTE**: It builds a hierarchy of movies linked together by `movie_link`, starting from movies released after the year 2000.
2. **Aggregations**: It calculates the count of info types (assuming 1 is a valid type) associated with movies, average popularity, and aggregates company names.
3. **Window Function**: It ranks movies for each actor based on the production year.
4. **Array Aggregation**: It collects distinct keywords associated with each movie into an array.
5. **Join Structures**: It utilizes outer joins to bring in optional company and keyword data while ensuring NULL values are properly managed.
6. **Complicated Filtering**: It includes complex predicates for production year and ensures valid `name` values.
7. **Bizarre Semantics**: The use of a hypothetical field `popularity_score` illustrates a field that doesn't exist in the provided schema, showcasing an unusual SQL pattern.
