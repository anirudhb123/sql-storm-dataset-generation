WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.depth + 1
    FROM 
        movie_link ml
    INNER JOIN 
        aka_title at ON ml.movie_id = at.id
    INNER JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    mh.title,
    mh.production_year,
    COUNT(ci.id) AS cast_count,
    STRING_AGG(DISTINCT ak.name, ', ') AS actors,
    AVG(CASE WHEN mt.info_type_id = (SELECT id FROM info_type WHERE info = 'rating') 
             THEN CAST(mt.info AS FLOAT) 
             ELSE NULL END) AS avg_rating,
    MIN(CASE WHEN mt.info_type_id = (SELECT id FROM info_type WHERE info = 'rating') 
             THEN CAST(mt.info AS FLOAT) 
             ELSE NULL END) AS min_rating,
    MAX(CASE WHEN mt.info_type_id = (SELECT id FROM info_type WHERE info = 'rating') 
             THEN CAST(mt.info AS FLOAT) 
             ELSE NULL END) AS max_rating
FROM 
    MovieHierarchy mh
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
LEFT JOIN 
    aka_name ak ON ci.person_id = ak.person_id
LEFT JOIN 
    movie_info mt ON mt.movie_id = mh.movie_id
WHERE 
    mh.depth <= 2
GROUP BY 
    mh.movie_id, mh.title, mh.production_year
ORDER BY 
    mh.production_year DESC, cast_count DESC
LIMIT 10;

**Query Breakdown:**
1. **Recursive CTE (MovieHierarchy)**: This constructs a hierarchy of movies starting from the base movie titles and including their linked movies up to two levels deep.
2. **Main Query**: Retrieves the title, production year, and other metrics associated with the movies:
   - **Count of Cast Members**: Total number of distinct cast members per movie.
   - **Actors**: Concatenated string of distinct actor names.
   - **Average, Minimum, Maximum Ratings**: Calculated using conditional aggregation based on movie information type.
3. **LEFT JOINs**: Ensure that even movies without any cast or ratings are included in the results.
4. **Filter by Depth**: Limits the results to two levels of linked movies.
5. **Ordering and Limiting**: Sorts by production year and cast count and limits the output to the top 10 results.
