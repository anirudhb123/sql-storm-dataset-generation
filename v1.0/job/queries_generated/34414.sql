WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        NULL::integer AS parent_movie_id,
        0 AS level
    FROM aka_title mt
    WHERE mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.movie_id AS parent_movie_id,
        mh.level + 1
    FROM movie_link ml
    JOIN aka_title at ON ml.linked_movie_id = at.id
    JOIN MovieHierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    mh.parent_movie_id,
    mh.level,
    STRING_AGG(DISTINCT ak.name, ', ') AS actors,
    COUNT(DISTINCT mc.company_id) AS company_count,
    AVG(mi.info IS NOT NULL)::integer AS has_additional_info
FROM MovieHierarchy mh
LEFT JOIN complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN cast_info ci ON cc.subject_id = ci.person_id
LEFT JOIN aka_name ak ON ci.person_id = ak.person_id
LEFT JOIN movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN movie_info mi ON mh.movie_id = mi.movie_id
WHERE mh.level <= 3
GROUP BY 
    mh.movie_id, 
    mh.title, 
    mh.production_year, 
    mh.parent_movie_id, 
    mh.level
ORDER BY 
    mh.production_year DESC, 
    COUNT(DISTINCT ak.name) DESC;

### Explanation of the Query:

1. **Recursive CTE (`MovieHierarchy`)**: This starts with a base query that fetches all movies from the `aka_title` table and recursively joins with `movie_link` to fetch linked movies, creating a hierarchy of movies.

2. **Columns Selected**:
   - `movie_id`, `title`, and `production_year` are pulled from the CTE.
   - The `parent_movie_id` and `level` are included to show the hierarchy of movie relationships.

3. **Join Operations**:
   - A `LEFT JOIN` with `complete_cast` gets all movies within the hierarchy.
   - Another `LEFT JOIN` with `cast_info` is used to get the actors' information.
   - Joined with `aka_name` to fetch the names of actors.
   - Joined with `movie_companies` to get the companies associated with the movies.
   - Joined with `movie_info` to check for additional information associated with the movie.

4. **Aggregations**:
   - `STRING_AGG` is used to concatenate actor names into a single string.
   - `COUNT` is used to count distinct company IDs, giving a count of companies involved.
   - The average check on `mi.info` indicates whether additional information exists.

5. **WHERE Clause**: Limits the levels of movie depth to a maximum of 3 to keep the results manageable.

6. **GROUP BY**: Ensures that the results are grouped correctly based on the movie details.

7. **ORDER BY**: Results are sorted by `production_year` (newest first) and then by the number of distinct actors involved in the movie (most actors first) to highlight popular movies.

The SQL query is designed to benchmark performance by evaluating its execution plan and checking the efficiency of joins and aggregations on potentially large sets of movie data.
