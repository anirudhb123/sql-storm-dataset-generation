WITH recursive movie_hierarchy AS (
    SELECT mt.id AS movie_id, 
           mt.title, 
           mt.production_year, 
           NULL::integer AS parent_movie_id
    FROM aka_title mt
    WHERE mt.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')

    UNION ALL

    SELECT mt.id AS movie_id, 
           mt.title, 
           mt.production_year, 
           mh.movie_id AS parent_movie_id
    FROM aka_title mt
    JOIN movie_link ml ON ml.linked_movie_id = mt.id
    JOIN movie_hierarchy mh ON mh.movie_id = ml.movie_id
)

SELECT 
    distinct an.person_id, 
    an.name AS actor_name, 
    m.title AS movie_title, 
    mh.title AS linked_title,
    m.production_year,
    COALESCE(k.keyword, 'No Keyword') AS movie_keyword,
    count(DISTINCT c.movie_id) OVER (PARTITION BY an.person_id) AS total_movies,
    row_number() OVER (PARTITION BY an.person_id ORDER BY count(DISTINCT c.movie_id) DESC) AS rank
FROM aka_name an
JOIN cast_info c ON an.person_id = c.person_id
JOIN aka_title m ON c.movie_id = m.id
LEFT JOIN movie_keyword mk ON m.id = mk.movie_id
LEFT JOIN keyword k ON mk.keyword_id = k.id
LEFT JOIN movie_hierarchy mh ON mh.movie_id = m.id
WHERE m.production_year IS NOT NULL 
  AND m.production_year >= 2000 
  AND (k.keyword IS NULL OR k.keyword NOT LIKE 'Action%')
  AND EXISTS (
      SELECT 1
      FROM complete_cast cc 
      JOIN movie_info mi ON mi.movie_id = m.id
      WHERE cc.movie_id = m.id
        AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Budget')
        AND mi.info IS NOT NULL
      LIMIT 1
  )
ORDER BY total_movies DESC, an.name;

### Explanation:
1. **Common Table Expression (CTE)**:
   - The `movie_hierarchy` CTE recursively retrieves movies along with their linked titles. It allows for the establishment of relationships between a movie and any sequels or properties via the `movie_link` table.

2. **Main Query**:
   - Selects distinct actor information along with various details about their appearances in movies.
   - Performs multiple joins across different tables to gather necessary information about movies and keywords.
   - **NULL Logic & COALESCE**: Uses `COALESCE` to provide a default value ('No Keyword') where there are no associated keywords for a movie.
   
3. **Window Functions**:
   - Uses `count(DISTINCT c.movie_id) OVER (PARTITION BY an.person_id)` to determine the total number of movies an actor has appeared in.
   - The use of `row_number()` assigns a rank to actors based on their total movies, ordered in descending order.

4. **Correlated Subquery**:
   - Checks if the movie has budget information through a subquery with EXISTS, ensuring the movie meets certain criteria.

5. **Predicates**:
   - Filters movies that are released starting from 2000 and excludes those with keywords starting with 'Action'.

This elaborate query serves as a benchmarking tool, capable of testing multiple SQL features like joins, window functions, filtering logic, and recursion.
