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
        at.title,
        at.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    WHERE 
        mh.level < 5
)

SELECT 
    ak.name AS actor_name,
    at.title AS movie_title,
    mh.level AS hierarchy_level,
    mt.production_year AS year_produced,
    COUNT(DISTINCT mct.id) AS company_count,
    AVG(CASE WHEN mi.info IS NOT NULL THEN LENGTH(mi.info) ELSE 0 END) AS avg_info_length,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords
FROM 
    cast_info ci
JOIN 
    aka_name ak ON ci.person_id = ak.person_id
JOIN 
    aka_title at ON ci.movie_id = at.id
JOIN 
    movie_companies mc ON at.id = mc.movie_id
LEFT JOIN 
    company_name c ON mc.company_id = c.id
LEFT JOIN 
    movie_info mi ON at.id = mi.movie_id
LEFT JOIN 
    movie_keyword mk ON at.id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
JOIN 
    movie_hierarchy mh ON at.id = mh.movie_id
WHERE 
    ak.name IS NOT NULL
    AND (at.production_year IS NOT NULL OR at.production_year >= 2000)
GROUP BY 
    ak.name, at.title, mh.level, mt.production_year
ORDER BY 
    hierarchy_level DESC, year_produced DESC, actor_name
LIMIT 50;

### Explanation:
- **CTE (Common Table Expression)**: The `movie_hierarchy` CTE recursively fetches movies produced since 2000 and their linked movies to a maximum depth of 5 levels.
- **Joins**: Multiple joins establish relationships between actors, movies, companies, info types, and keywords.
- **NULL Logic**: The `WHERE` clause checks for NULL values, ensuring only relevant records are processed.
- **Aggregations**: The query counts distinct companies associated with each movie and computes the average length of any associated information, while also aggregating keywords into a comma-separated list.
- **Sorting and Limitation**: The results are ordered by the hierarchy level and production year, limiting the final output to 50 records for performance benchmarking.

This complex structure gives a comprehensive view of actors in a substantial network of movies while integrating various SQL features for advanced SQL querying.
