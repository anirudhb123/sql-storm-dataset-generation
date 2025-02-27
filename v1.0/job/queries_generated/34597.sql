WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        ak.title,
        ak.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title ak ON ml.linked_movie_id = ak.movie_id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    ak.name,
    mt.title,
    mt.production_year,
    ROW_NUMBER() OVER (PARTITION BY ak.name ORDER BY mt.production_year DESC) AS row_num,
    COUNT(DISTINCT mc.company_id) OVER (PARTITION BY ak.name) AS company_count,
    COALESCE(NULLIF(gc.gender, 'M'), 'Unknown') AS gender_description,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords_used
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    title mt ON ci.movie_id = mt.id
LEFT JOIN 
    movie_companies mc ON mt.id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    person_info pi ON ak.person_id = pi.person_id
LEFT JOIN 
    name gc ON ak.person_id = gc.imdb_id
LEFT JOIN 
    movie_keyword mkp ON mt.id = mkp.movie_id
LEFT JOIN 
    keyword kw ON mkp.keyword_id = kw.id
WHERE 
    mt.production_year BETWEEN 2000 AND 2023
    AND ak.name IS NOT NULL
GROUP BY 
    ak.name, mt.title, mt.production_year, gc.gender
ORDER BY 
    ak.name, mt.production_year DESC
LIMIT 100;

This query efficiently retrieves information about actors (aka_name), the movies they've acted in (aka_title), and related data from other tables, while including various SQL constructs such as:

- **Recursive CTE** (`movie_hierarchy`) that builds a hierarchy of movies released since 2000.
- **Window functions** with `ROW_NUMBER()` and `COUNT()` to provide context on the number of companies involved with the movies.
- **LEFT JOINs** to ensure comprehensive data retrieval from potentially sparse data relationships and incorporate NULL handling.
- **String aggregation** for collecting keywords in a comma-separated format.
- **COALESCE** and **NULLIF** functions to manage gender info and handle edge cases. 

The result set is ordered, grouped, and limited to the first 100 entries to manage performance and result relevance for the benchmarking task.
