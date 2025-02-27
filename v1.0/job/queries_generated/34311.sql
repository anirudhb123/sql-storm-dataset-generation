WITH RECURSIVE MovieHierarchy AS (
    -- Base case: Select all movies with their direct links
    SELECT 
        mt.movie_id,
        mt.linked_movie_id,
        1 AS level
    FROM 
        movie_link mt
    WHERE 
        mt.link_type_id = (SELECT id FROM link_type WHERE link = 'related_to')

    UNION ALL

    -- Recursive case: Join to find linked movies
    SELECT 
        mt.movie_id,
        ml.linked_movie_id,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.linked_movie_id
    WHERE 
        ml.link_type_id = (SELECT id FROM link_type WHERE link = 'related_to')
),
MovieScores AS (
    SELECT 
        t.id AS movie_id,
        COALESCE(SUM(CASE WHEN r.role = 'Actor' THEN 1 ELSE 0 END), 0) AS actor_count,
        COALESCE(SUM(CASE WHEN r.role = 'Director' THEN 1 ELSE 0 END), 0) AS director_count
    FROM 
        title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    LEFT JOIN 
        role_type r ON ci.role_id = r.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id
),
TopMovies AS (
    SELECT 
        ms.movie_id,
        ms.actor_count,
        ms.director_count,
        ROW_NUMBER() OVER (ORDER BY (ms.actor_count + ms.director_count) DESC) AS overall_rank
    FROM 
        MovieScores ms
    WHERE 
        ms.actor_count > 0
    AND 
        ms.director_count > 0
)

SELECT 
    t.title,
    COALESCE(h.movie_id, 0) AS linked_movie_id,
    ts.overall_rank,
    ts.actor_count,
    ts.director_count
FROM 
    title t
LEFT JOIN 
    MovieHierarchy h ON t.id = h.movie_id
JOIN 
    TopMovies ts ON t.id = ts.movie_id
WHERE 
    t.title ILIKE '%action%'
AND 
    t.production_year BETWEEN 2010 AND 2023
ORDER BY 
    ts.overall_rank ASC, 
    ts.actor_count DESC
LIMIT 50;

### Explanation:

1. **Common Table Expressions (CTEs)**:
   - `MovieHierarchy`: This recursive CTE builds a hierarchy of movies that are linked to each other based on a specific type of relationship, specifically the 'related_to' link type.
   - `MovieScores`: This CTE calculates the number of actors and directors for each movie that was produced from the year 2000 onwards.
   - `TopMovies`: This CTE ranks movies based on the combined counts of actors and directors.
  
2. **Main Query**:
   - Retrieves the title of movies that contain 'action', produced between 2010 and 2023, and includes the linked movie IDs from the hierarchy.
   - Joins the titles with the scores to include the overall rank and counts of actors and directors.
   - Uses a `LEFT JOIN` with `MovieHierarchy` to include potential linked movies even if there are no direct links.
  
3. **Filters and Ordering**:
   - Only films with 'action' in the title and produced in a specified year range are included.
   - Ordered by rank and actor count.

4. **NULL Logic & Expressions**:
   - Use of `COALESCE` to handle potential NULL values for linked movies or counts, ensuring output is consistent.
