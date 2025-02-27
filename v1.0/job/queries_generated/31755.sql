WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level,
        NULL::integer AS parent_id
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1,
        mh.movie_id AS parent_id
    FROM 
        MovieHierarchy mh
    JOIN 
        aka_title m ON mh.movie_id = m.episode_of_id
)
SELECT 
    a.name AS actor_name,
    m.title AS movie_title,
    mh.level,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
    COUNT(DISTINCT cc.id) AS cast_count,
    COALESCE(avg(year(m.production_year)), 0) AS avg_production_year
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    MovieHierarchy mh ON ci.movie_id = mh.movie_id
JOIN 
    aka_title m ON mh.movie_id = m.id
LEFT JOIN 
    movie_keyword mk ON m.id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
LEFT JOIN 
    complete_cast cc ON m.id = cc.movie_id
GROUP BY 
    a.name, m.title, mh.level
HAVING 
    COUNT(DISTINCT ci.movie_id) > 1
ORDER BY 
    mh.level DESC, avg(m.production_year) DESC
LIMIT 100;

### Explanation:
1. **Common Table Expression (CTE)**: This recursive CTE, `MovieHierarchy`, constructs a hierarchy of movies allowing for episodes to show from their parent series. 
   
2. **Main Query**:
   - Joins the actor names (`aka_name`) with the `cast_info`, linking them to the hierarchical movie structure.
   - The movie titles and their levels within the hierarchy are selected.
   - Aggregates keywords associated with each movie using `STRING_AGG`.
   - Counts distinct cast members for each movie.
   - Computes the average production year of the movies using `COALESCE` to handle any potential NULLs.

3. **Group By and Having Clauses**: Grouped by actor name, movie title, and level; filtering those who appeared in more than one movie.

4. **Ordering and Limiting**: The results are ordered by level (to show parent movies before children) and average production year, with a limit on the output.

This query will indicate which actors have significant roles in series and movies while showcasing various SQL functionalities for performance benchmarking.
