WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        id AS movie_id,
        title,
        production_year,
        NULL AS parent_movie_id,
        0 AS depth 
    FROM 
        aka_title 
    WHERE 
        kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
    UNION ALL
    SELECT 
        mt.id,
        mt.title,
        mt.production_year,
        mh.movie_id AS parent_movie_id,
        mh.depth + 1
    FROM 
        aka_title mt
    JOIN 
        movie_link ml ON mt.id = ml.linked_movie_id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
),
RankedTitles AS (
    SELECT 
        at.title, 
        COALESCE(ac.name, 'Unknown') AS actor_name,
        at.production_year,
        COUNT(ac.id) OVER (PARTITION BY at.id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.title) AS year_rank
    FROM 
        aka_title at
    LEFT JOIN 
        cast_info ci ON at.id = ci.movie_id
    LEFT JOIN 
        aka_name ac ON ci.person_id = ac.person_id
)
SELECT 
    mh.title,
    mh.production_year,
    rt.actor_name,
    rt.actor_count,
    CASE 
        WHEN rt.actor_count IS NULL THEN 'No Actors'
        WHEN rt.actor_count > 5 THEN 'Blockbuster Cast'
        ELSE 'Small Cast'
    END AS cast_size,
    (SELECT COUNT(DISTINCT mk.keyword)
     FROM movie_keyword mk
     JOIN aka_title amt ON amt.id = mk.movie_id
     WHERE amt.production_year = mh.production_year) AS keyword_count,
    (SELECT AVG(CASE WHEN si.info_type_id = (SELECT id FROM info_type WHERE info='Budget') 
                     THEN CAST(si.info AS float) ELSE NULL END)
     FROM movie_info si
     WHERE si.movie_id = mh.movie_id) AS average_budget
FROM 
    MovieHierarchy mh
LEFT JOIN 
    RankedTitles rt ON mh.movie_id = rt.movie_id
WHERE 
    mh.depth < 3
ORDER BY 
    mh.production_year DESC, mh.title;

### Explanation:
1. **Common Table Expressions (CTEs)**:
   - `MovieHierarchy` recursively gathers movies and their relationships to build a hierarchy.
   - `RankedTitles` aggregates titles along with actor names and counts the actors per movie, and ranks them by year.

2. **Complex Logic**:
   - The outer query selects from the hierarchical view and combines it with actor data, incorporating a case statement for categorizing the size of the cast.
   - It includes counts of distinct keywords related to the movie's production year and calculates an average budget for movies, demonstrating a mix of analytical processes, subqueries, and aggregations.
  
3. **Handling NULLs & Edge Cases**:
   - It uses `COALESCE` to handle NULL actor names, ensuring that even if no actor is associated with a movie, it returns 'Unknown' instead of NULL.
   - It manages edge cases with the average budget calculation, defaulting to NULL where needed.

4. **Order of Results**:
   - Results are ordered first by the production year in descending order and then by title for organized output.

This query incorporates several advanced SQL concepts, showcasing the potential for performance benchmarking based on various movie attributes and relationships.
