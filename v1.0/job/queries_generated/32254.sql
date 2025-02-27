WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mc.movie_id,
        t.title,
        t.production_year,
        1 AS level
    FROM 
        movie_companies mc
    JOIN 
        aka_title t ON mc.movie_id = t.movie_id
    WHERE 
        mc.company_type_id IN (SELECT id FROM company_type WHERE kind = 'Distributor')
    
    UNION ALL
    
    SELECT 
        m.movie_id,
        t.title,
        t.production_year,
        h.level + 1
    FROM 
        MovieHierarchy h
    JOIN 
        movie_link ml ON h.movie_id = ml.linked_movie_id
    JOIN 
        aka_title t ON ml.movie_id = t.movie_id
)

SELECT 
    h.title,
    h.production_year,
    string_agg(DISTINCT CONCAT_WS(' ', a.name, coalesce(c.role_id::text, 'Unknown'))) AS cast_details,
    COUNT(DISTINCT mk.keyword_id) AS keyword_count,
    COUNT(DISTINCT mi.info_type_id) AS info_type_count,
    ROW_NUMBER() OVER (PARTITION BY h.production_year ORDER BY h.level DESC) AS ranking
FROM 
    MovieHierarchy h
LEFT JOIN 
    cast_info ci ON ci.movie_id = h.movie_id
LEFT JOIN 
    aka_name a ON a.person_id = ci.person_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = h.movie_id
LEFT JOIN 
    movie_info mi ON mi.movie_id = h.movie_id
WHERE 
    h.production_year IS NOT NULL 
    AND (h.level < 3 OR h.production_year > 2000)
GROUP BY 
    h.title, h.production_year
HAVING 
    COUNT(DISTINCT ci.id) > 2
ORDER BY 
    h.production_year DESC, ranking ASC;

### Explanation of the Query:
1. **Recursive Common Table Expression (CTE)**: A recursive CTE named `MovieHierarchy` is created to track movies and their links to one another, starting with movies produced by distributors.
2. **Main Query Logic**:
   - Joining multiple tables to gather relevant movie information, including casting details, keywords associated with the movie, and various info types.
   - Using `LEFT JOIN` clauses to ensure that even movies without cast or keywords are included.
3. **Aggregations and Calculations**:
   - `STRING_AGG` function to concatenate names and roles of cast members for each movie.
   - `COUNT` functions to count distinct keywords and info types.
   - Utilizing `ROW_NUMBER` for qualification and ordering of movie entries grouped by production year.
4. **Filters and Conditions**:
   - The `WHERE` clause filters out entries with a NULL production year and applies specific conditions based on the hierarchy level and production year.
   - The `HAVING` clause ensures movies have more than two cast members.
5. **Ordering**: Finally, the results are sorted primarily by production year in descending order and then by ranking.
