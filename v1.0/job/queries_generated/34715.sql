WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year = (SELECT MAX(production_year) FROM aka_title)

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        mt.title,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.id
)

SELECT 
    ak.name AS actor_name,
    at.title AS movie_title,
    at.production_year,
    COALESCE(GROUP_CONCAT(DISTINCT kw.keyword), 'No Keywords') AS keywords,
    COUNT(*) OVER (PARTITION BY ak.name) AS total_movies,
    MAX(CASE 
        WHEN mc.company_type_id = ct.id THEN 'Produced by ' || cn.name
        ELSE NULL 
    END) AS production_company,
    ROW_NUMBER() OVER (PARTITION BY ak.name ORDER BY at.production_year DESC) AS rn
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    aka_title at ON ci.movie_id = at.id
LEFT JOIN 
    movie_keyword mk ON at.id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
LEFT JOIN 
    movie_companies mc ON at.id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    company_type ct ON mc.company_type_id = ct.id
WHERE 
    ak.name IS NOT NULL 
    AND at.production_year IS NOT NULL
    AND (at.kind_id IS NULL OR ct.kind = 'Production')
GROUP BY 
    ak.name, at.title, at.production_year
HAVING 
    COUNT(mk.keyword_id) >= 1
ORDER BY 
    total_movies DESC, ak.name, at.production_year DESC
LIMIT 100;

This query performs the following key actions:

1. **CTE (WITH RECURSIVE)**: Creates a recursive common table expression to construct a movie hierarchy based on linked movies, starting with those produced in the latest year.
2. **Outer Joins**: Uses LEFT JOINs to include keywords and company details while ensuring that movies without corresponding entries are still displayed.
3. **Aggregations and Grouping**: Counts and concatenates related keywords per actor and aggregates movie data.
4. **Window Functions**: Applies `ROW_NUMBER()` to rank movies per actor and counts total movies per actor using `COUNT() OVER`.
5. **COALESCE**: Uses this function to handle cases where there are no keywords associated with a movie.
6. **NULL Logic**: Uses `IS NULL` checks in the `WHERE` clause to ensure that only relevant records are retrieved.

This complex query is well-suited for performance benchmarking as it involves multiple table interactions, calculations, and orderings, challenging the database's optimization capabilities.
