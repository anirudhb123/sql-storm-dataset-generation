WITH RECURSIVE MovieHierarchy AS (
    SELECT m.id AS movie_id, 
           m.title, 
           m.production_year, 
           NULL::integer AS parent_movie_id
    FROM aka_title m
    WHERE m.kind_id = 1  -- Assuming 1 corresponds to movies

    UNION ALL

    SELECT m.id, 
           m.title, 
           m.production_year, 
           mh.movie_id
    FROM aka_title m
    JOIN movie_link ml ON ml.linked_movie_id = m.id
    JOIN MovieHierarchy mh ON mh.movie_id = ml.movie_id
),
ActorMovieCount AS (
    SELECT ci.person_id, 
           COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM cast_info ci
    JOIN aka_name an ON an.person_id = ci.person_id
    WHERE an.name IS NOT NULL
    GROUP BY ci.person_id
),
MovieKeywords AS (
    SELECT mk.movie_id, 
           STRING_AGG(k.keyword, ', ') AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON k.id = mk.keyword_id
    GROUP BY mk.movie_id
)
SELECT mh.movie_id, 
       mh.title, 
       mh.production_year, 
       COALESCE(ak.name, 'Unknown') AS actor_name,
       COALESCE(ak.movie_count, 0) AS actor_movie_count,
       COALESCE(mk.keywords, 'No keywords') AS keywords
FROM MovieHierarchy mh
LEFT JOIN ActorMovieCount ak ON ak.person_id = (
    SELECT ci.person_id 
    FROM cast_info ci 
    WHERE ci.movie_id = mh.movie_id 
    ORDER BY ci.nr_order 
    LIMIT 1
)
LEFT JOIN MovieKeywords mk ON mk.movie_id = mh.movie_id
WHERE (mh.production_year > 2000 OR mh.title LIKE 'Star%')
  AND mh.movie_id IS NOT NULL
ORDER BY mh.production_year DESC, mh.title
LIMIT 100;

This query utilizes:

1. **Recursive CTE `MovieHierarchy`**: It builds a hierarchy of movies using recursive relationships based on links.
2. **CTEs**: To count the number of movies an actor has appeared in and to aggregate keywords associated with those movies.
3. **NULL Logic**: Using `COALESCE` to handle possible NULLs for actor names and keyword descriptions.
4. **Complicated predicates**: The WHERE clause combines conditions on production year and title, demonstrating conditional logic.
5. **String Aggregation**: Combining multiple keywords into a single field for easier analysis.
6. **Outer Joins**: Left joins are used to ensure all movies are included, even if there are no relevant actors or keywords.
7. **Ordering**: Results are sorted by production year and movie title.

This SQL query aims to benchmark performance across complex joins, aggregations, and filtering in a movie database context.
