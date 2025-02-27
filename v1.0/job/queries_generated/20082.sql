WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        CAST(mt.title AS VARCHAR(255)) AS full_title,
        mt.kind_id,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        CAST(CONCAT(mh.full_title, ' -> ', at.title) AS VARCHAR(255)) AS full_title,
        at.kind_id,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    ak.name AS actor_name,
    at.title AS movie_title,
    mh.full_title AS hierarchical_title,
    mh.production_year,
    COALESCE(ct.kind, 'Unknown') AS company_type,
    COUNT(DISTINCT kc.keyword) AS keyword_count,
    SUM(CASE 
            WHEN mi.info IS NOT NULL THEN 1 
            ELSE 0 
        END) AS info_entry_count,
    RANK() OVER (PARTITION BY mh.production_year ORDER BY COUNT(DISTINCT kc.keyword) DESC) AS keyword_rank
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    aka_title at ON ci.movie_id = at.id
LEFT JOIN 
    company_name cn ON cn.id = (SELECT mc.company_id
                                 FROM movie_companies mc
                                 WHERE mc.movie_id = at.id
                                 LIMIT 1)
LEFT JOIN 
    company_type ct ON cn.name = ct.kind
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = at.id
LEFT JOIN 
    keyword kc ON mk.keyword_id = kc.id
LEFT JOIN 
    movie_info mi ON mi.movie_id = at.id
LEFT JOIN 
    movie_hierarchy mh ON mh.movie_id = at.id
WHERE 
    at.production_year >= 2000 
    AND ak.name IS NOT NULL
    AND ak.name <> ''
    AND (ci.note IS NULL OR ci.note NOT LIKE '%cameo%')
GROUP BY 
    ak.name, at.title, mh.full_title, mh.production_year, ct.kind
HAVING 
    COUNT(DISTINCT kc.keyword) > 0
ORDER BY 
    keyword_rank, mh.production_year DESC;

This SQL query retrieves an extensive performance benchmark involving multiple tables and constructs:

1. **Common Table Expressions (CTE)**: The `movie_hierarchy` CTE uses recursion to create a linkage of movies based on links to other movies.
2. **Joins**: It uses several types of joins including inner and left joins to connect actors, movies, companies, and keywords.
3. **Aggregations**: It counts distinct keywords and sums the non-null entries in the `movie_info` table.
4. **Window Functions**: RANK() is used to rank the movies based on the count of keywords within each production year.
5. **Complex where and having clauses**: These help filter out unnecessary results, ensuring meaningful data retrieval.
6. **Case and COALESCE**: To ensure that missing values are handled, providing defaults where necessary.

The use of conditions checks for NULL values and matches various patterns while the structural complexity showcases how sophisticated SQL queries can become when dealing with intricate relations between data entities.
