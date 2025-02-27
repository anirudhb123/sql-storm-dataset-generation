WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000  -- Only consider movies from 2000 onwards
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id AS movie_id,
        a.title,
        a.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title a ON ml.linked_movie_id = a.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    m.id AS movie_id,
    m.title AS original_title,
    m.production_year,
    COUNT(DISTINCT c.person_id) AS total_cast,
    ARRAY_AGG(DISTINCT a.name) FILTER (WHERE c.role_id IS NOT NULL) AS cast_names,
    MAX(o.average_rating) AS highest_rating
FROM 
    movie_hierarchy m
LEFT JOIN 
    cast_info c ON m.movie_id = c.movie_id
LEFT JOIN 
    aka_name a ON c.person_id = a.person_id
LEFT JOIN LATERAL (
    SELECT 
        mi.info, 
        AVG(CAST(mi.info AS FLOAT)) AS average_rating
    FROM 
        movie_info mi
    WHERE 
        mi.movie_id = m.movie_id AND 
        mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Rating')
    GROUP BY 
        mi.info
) o ON true  -- Getting average ratings via lateral join

WHERE 
    m.level <= 2  -- Limiting to original movies and their direct sequels
GROUP BY 
    m.id, m.title, m.production_year
ORDER BY 
    m.production_year DESC, total_cast DESC;

### Explanation of the Query:

1. **Common Table Expression (CTE)**: A recursive CTE named `movie_hierarchy` retrieves original movies from 2000 onwards and any linked movies (e.g., sequels or related films) within two levels of connection.
  
2. **Aggregation**: The main SELECT statement aggregates information about these films by counting distinct cast members and collects their names.

3. **LATERAL JOIN**: A lateral join is used to calculate the average rating of each movie, which is extracted using a subquery. The subquery filters `movie_info` to obtain ratings based on a specific `info_type`.

4. **Filters**: The query limits results to direct sequels or linked movies up to two levels deep from original movies.

5. **Sorting**: Finally, results are ordered by production year and the total number of cast members, which will help in performance benchmarking.

This complex query incorporates various SQL constructs for robust performance testing and analysis.
