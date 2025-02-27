WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        0 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL
  
    UNION ALL
  
    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.movie_id = at.id
    JOIN 
        movie_hierarchy mh ON mh.movie_id = ml.movie_id
)
SELECT 
    ak.name AS actor_name, 
    mk.keyword AS movie_keyword, 
    mh.title AS movie_title, 
    mh.production_year AS movie_year,
    COUNT(DISTINCT ci.movie_id) AS total_movies,
    AVG(EXTRACT(EPOCH FROM (mo.info ORDER BY mo.info_type_id DESC) FILTER (WHERE mo.info_type_id = 1))/(60*60)) AS avg_runtime_hours,
    STRING_AGG(DISTINCT cn.name, ', ') AS companies,
    MAX(mo.note) AS latest_note
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    movie_hierarchy mh ON ci.movie_id = mh.movie_id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    movie_info mo ON mh.movie_id = mo.movie_id
WHERE 
    ak.name IS NOT NULL 
    AND mk.keyword IS NOT NULL
    AND mo.info IS NOT NULL
    AND (mh.production_year BETWEEN 1990 AND 2020)
GROUP BY 
    ak.name, mk.keyword, mh.title, mh.production_year
HAVING 
    COUNT(DISTINCT ci.movie_id) > 5
ORDER BY 
    total_movies DESC, 
    avg_runtime_hours DESC
LIMIT 10;

### Explanation:
- **CTE (Common Table Expression)**: The `movie_hierarchy` CTE is a recursive query to create a hierarchy of movies linked by their relationships.
- **Joins**: An array of joins connects `aka_name`, `cast_info`, `movie_hierarchy`, `movie_keyword`, `movie_companies`, `company_name`, and `movie_info` to gather all necessary data.
- **Filtering Conditions**: Various conditions ensure that only relevant data is selected (e.g., non-null names and keywords, production years between 1990 and 2020).
- **Aggregations**: Using `COUNT`, `AVG`, and `STRING_AGG` to summarize results related to actors, movies, and companies.
- **Window Function**: The avg runtime calculation involves filtering out specific information types.
- **HAVING Clause**: Restricts results to actors involved in more than 5 distinct movies, pushing for significant contributions.
- **Complexity**: The SQL showcases multiple SQL constructs and showcases the intricacy of aggregating and filtering data across multiple related tables.
