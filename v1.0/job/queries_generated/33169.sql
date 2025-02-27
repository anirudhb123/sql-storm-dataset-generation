WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        1 AS level,
        CAST(mt.id AS VARCHAR) AS path
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        a.title,
        a.production_year,
        a.kind_id,
        mh.level + 1,
        CAST(mh.path || ' -> ' || ml.linked_movie_id AS VARCHAR)
    FROM 
        movie_link ml
    JOIN 
        aka_title a ON a.id = ml.linked_movie_id
    JOIN 
        MovieHierarchy mh ON mh.movie_id = ml.movie_id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    mh.level,
    STRING_AGG(DISTINCT a.name, ', ') AS actors,
    COUNT(DISTINCT mc.company_id) AS company_count,
    AVG(CASE 
            WHEN mi.info IS NOT NULL THEN LENGTH(mi.info)
            ELSE 0
        END) AS average_info_length
FROM 
    MovieHierarchy mh
LEFT JOIN 
    complete_cast cc ON cc.movie_id = mh.movie_id
LEFT JOIN 
    cast_info ci ON ci.movie_id = cc.movie_id
LEFT JOIN 
    aka_name a ON a.person_id = ci.person_id
LEFT JOIN 
    movie_companies mc ON mc.movie_id = mh.movie_id
LEFT JOIN 
    movie_info mi ON mi.movie_id = mh.movie_id
WHERE 
    mh.production_year >= 2000
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, mh.level
HAVING 
    COUNT(DISTINCT a.name) > 1
ORDER BY 
    mh.production_year DESC, mh.level DESC;

### Explanation:

1. **Recursive CTE (`MovieHierarchy`)**: This part builds a hierarchy of movies by recursively joining the `movie_link` table to find all linked movies and their details.

2. **Selection and Aggregation**: After forming the hierarchy, a selection is made to include the movie's title, production year, and the level of hierarchy. 

3. **LEFT JOINs**:
   - `complete_cast` and `cast_info` are joined to obtain the names of actors for each movie.
   - `movie_companies` retrieves associated companies, and `movie_info` is used to gather additional information about the movies.

4. **Predicates**:
   - The `WHERE` clause filters for movies produced from the year 2000 onwards.
   - The `HAVING` clause ensures that only movies featuring more than one unique actor are included.

5. **Aggregates and Calculations**:
   - `STRING_AGG` is utilized to concatenate actor names into a single string.
   - `COUNT` calculates the number of distinct companies associated with each movie.
   - `AVG` computes the average length of any available movie information.

6. **Order by Clause**: Results are ordered by the year of production in descending order, followed by the hierarchy level in descending order, allowing for easy identification of recent and prominent movies in the hierarchy.
