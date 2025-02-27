WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        akat.title,
        akat.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    INNER JOIN 
        aka_title akat ON ml.linked_movie_id = akat.id
    INNER JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    ah.name AS actor_name,
    mh.title AS movie_title,
    mh.production_year,
    COUNT(DISTINCT mc.company_id) AS company_count,
    AVG(CASE 
            WHEN mi.info IS NULL THEN 0 
            ELSE CHAR_LENGTH(mi.info) 
        END) AS avg_info_length,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
    ROW_NUMBER() OVER (PARTITION BY ah.name ORDER BY mh.production_year DESC) AS actor_movie_rank,
    COALESCE((SELECT COUNT(*) FROM cast_info ci WHERE ci.movie_id = mh.movie_id AND ci.role_id IS NULL), 0) AS uncredited_role_count
FROM 
    movie_hierarchy mh
JOIN 
    cast_info ci ON ci.movie_id = mh.movie_id
JOIN 
    aka_name ah ON ah.person_id = ci.person_id
LEFT JOIN 
    movie_companies mc ON mc.movie_id = mh.movie_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = mh.movie_id
LEFT JOIN 
    keyword kw ON kw.id = mk.keyword_id
LEFT JOIN 
    movie_info mi ON mi.movie_id = mh.movie_id AND mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'summary')
WHERE 
    mh.level <= 3
GROUP BY 
    ah.name, mh.movie_id, mh.title, mh.production_year
HAVING 
    COUNT(DISTINCT mc.company_id) > 0
ORDER BY 
    actor_movie_rank, mh.production_year DESC;

### Explanation of Constructs Used:

1. **CTE**: The recursive CTE `movie_hierarchy` allows fetching a hierarchy of movies linked together, up to 3 levels deep, filtering by "movie" kind.

2. **Joins**: It includes several joins to gather actor names, company information, keywords, and additional summaries for each movie.

3. **Aggregates**: Use of `COUNT` to calculate the number of companies associated with each movie, and `AVG` to compute the average length of information entries while employing a conditional expression to handle possible NULLs.

4. **String Aggregation**: `STRING_AGG` is used to compile a list of keywords associated with the movies.

5. **Window Function**: `ROW_NUMBER()` ranks the movies per actor based on production year to facilitate sorting.

6. **COALESCE with a Subquery**: Counts how many uncredited roles exist per movie, and returns 0 when none are found.

7. **HAVING**: The query filters results to only include those movies that have one or more associated companies.

8. **Complex Predicates**: Incorporates conditional expressions and NULL handling to deal with various edge cases in the data.

This SQL query exemplifies a complex and detailed performance benchmark scenario, integrating various advanced SQL features effectively.
