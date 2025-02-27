WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
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
        mh.level < 3  -- Limit depth of recursion to 3 levels
)
SELECT 
    m.movie_id,
    m.movie_title,
    m.production_year,
    COUNT(dc.id) AS total_cast,
    STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
    SUM(CASE WHEN mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Budget') THEN CAST(mi.info AS INTEGER) ELSE 0 END) AS total_budget,
    COUNT(DISTINCT cw.role) AS distinct_roles
FROM 
    movie_hierarchy m
LEFT JOIN 
    complete_cast cc ON m.movie_id = cc.movie_id
LEFT JOIN 
    cast_info c ON cc.subject_id = c.person_id
LEFT JOIN 
    movie_companies mc ON m.movie_id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    movie_info mi ON m.movie_id = mi.movie_id
LEFT JOIN 
    role_type cw ON cw.id = c.role_id
GROUP BY 
    m.movie_id, m.movie_title, m.production_year
HAVING 
    COUNT(dc.id) > 5  -- Filter to only include movies with more than 5 cast members
ORDER BY 
    total_budget DESC, m.production_year ASC, distinct_roles DESC;

### Explanation of the Query:
1. **Common Table Expression (CTE)**: A recursive CTE called `movie_hierarchy` is created to build a hierarchy of movies linked to each other up to 3 levels deep. 

2. **Main SELECT Statement**: This query pulls data from the `movie_hierarchy`, linking it to several tables to gather comprehensive information:
   - It counts the total cast members for each movie.
   - It aggregates company names associated with the movie using `STRING_AGG`.
   - It calculates the total budget from the `movie_info` table, only considering entries tagged with the 'Budget' info type.
   - It counts distinct roles assigned in the casting.

3. **Joins**: Uses left joins to include all movies from the `movie_hierarchy`, even if they lack associated cast or company data.

4. **HAVING clause**: The results are filtered to include only those movies that have more than 5 cast members.

5. **ORDER BY**: The results are ordered by total budget (descending), production year (ascending), and the count of distinct roles (descending). 

This complex query structure enhances performance benchmarking by evaluating multiple join strategies, aggregations, and conditions.
