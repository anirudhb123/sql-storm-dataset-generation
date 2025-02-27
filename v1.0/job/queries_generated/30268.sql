WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COALESCE(mt.episode_of_id, 0) AS parent_id,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        mt.title,
        mt.production_year,
        COALESCE(mt.episode_of_id, 0) AS parent_id,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN
        aka_title mt ON ml.linked_movie_id = mt.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    DISTINCT 
    ak.person_id,
    ak.name AS actor_name,
    mt.movie_id,
    mt.title AS movie_title,
    mt.production_year,
    mh.level AS hierarchical_level,
    kw.keyword AS movie_keyword,
    ROW_NUMBER() OVER (PARTITION BY ak.person_id ORDER BY mt.production_year DESC) AS movie_rank
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    MovieHierarchy mh ON ci.movie_id = mh.movie_id
JOIN 
    aka_title mt ON mh.movie_id = mt.id
LEFT JOIN 
    movie_keyword mk ON mt.movie_id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
WHERE 
    ak.name IS NOT NULL 
    AND ak.name <> ''
    AND mt.production_year IS NOT NULL 
    AND mt.production_year >= 2000
    AND (kw.keyword IS NULL OR kw.keyword NOT LIKE '%horror%')
ORDER BY 
    ak.person_id, mt.production_year DESC;

### Explanation:

1. **CTE (Common Table Expression)**: The query starts with a recursive CTE named `MovieHierarchy` that identifies all movies produced from the year 2000 onward, and recursively pulls linked movies to create a hierarchy based on linkage.

2. **SELECT Statement**: The query retrieves distinct actors, along with their associated movie details, including the movie’s hierarchical level.

3. **Joins**:
   - `aka_name` (for actor names) is joined with `cast_info` (to link actors to movies).
   - The CTE `MovieHierarchy` links current movies and their relationships.
   - `aka_title` retrieves the titles of the movies.
   - Left joins with `movie_keyword` and `keyword` allow for the inclusion of movie keywords, using conditions to filter out unwanted keywords.

4. **WHERE Clauses**: Filters are applied to ensure names are not NULL or empty, and restricts the production years to greater than or equal to 2000. Additionally, it excludes movies labeled with the keyword "horror".

5. **Window Function**: The `ROW_NUMBER()` window function is utilized to rank movies for each actor based on the production year in descending order.

6. **Order By**: Results are ordered first by `person_id` and then by `production_year` for better readability. 

This query demonstrates various complex SQL constructs while providing a comprehensive view of the movie hierarchy and actor participation over the years.
