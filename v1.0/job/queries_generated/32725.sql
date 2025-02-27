WITH RECURSIVE MovieHierarchy AS (
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
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    koh.k AS keyword,
    COUNT(DISTINCT k.id) AS keyword_count,
    AVG(mh.production_year) AS avg_production_year,
    STRING_AGG(DISTINCT a.name, ', ') AS actor_names
FROM 
    MovieHierarchy mh
JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    cast_info ci ON mh.movie_id = ci.movie_id
LEFT JOIN 
    aka_name a ON ci.person_id = a.person_id
LEFT JOIN 
    movie_info mi ON mh.movie_id = mi.movie_id
    AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Rating')
WHERE 
    mh.level = 0 
    AND k.keyword IS NOT NULL
GROUP BY 
    koh.k
HAVING 
    COUNT(DISTINCT k.id) > 1
ORDER BY 
    avg_production_year DESC
LIMIT 10;

### Explanation

1. **Common Table Expression (CTE):**
   - The `MovieHierarchy` CTE constructs a recursive structure to gather all linked movies and their direct relations. This is useful for analyzing sequels or movies tagged together.

2. **Joins:**
   - I've used a variety of joins, including inner joins to link movies to keywords and cast, as well as left joins to include information like ratings and actor names. 

3. **Aggregations:**
   - `COUNT(DISTINCT k.id)` counts unique keywords associated with the movies, while `AVG(mh.production_year)` calculates the average production year. 

4. **String Aggregation:**
   - `STRING_AGG(DISTINCT a.name, ', ')` provides a comma-separated list of actor names associated with the movies.

5. **Complex Filtering:**
   - The `HAVING` clause filters to show only those keywords that are associated with more than one movie, ensuring we get significant data.

6. **Order and Limit:**
   - The results are ordered by the average production year and limited to the top 10 entries for performance benchmarking.

This complex query utilizes multiple SQL constructs to provide an interesting analysis suited for benchmarking purposes, while also ensuring that the schema relationships are respected.
