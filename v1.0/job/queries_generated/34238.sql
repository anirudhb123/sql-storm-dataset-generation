WITH RECURSIVE actor_hierarchy AS (
    SELECT ak.id AS actor_id,
           ak.name AS actor_name,
           ci.movie_id,
           ak.name AS top_actor
    FROM aka_name ak
    JOIN cast_info ci ON ak.person_id = ci.person_id
    WHERE ak.name IS NOT NULL

    UNION ALL

    SELECT a.id AS actor_id,
           a.name AS actor_name,
           c.movie_id,
           ah.top_actor
    FROM aka_name a
    JOIN cast_info c ON a.person_id = c.person_id
    JOIN actor_hierarchy ah ON c.movie_id = ah.movie_id 
    WHERE a.id <> ah.actor_id
)

SELECT 
    t.title AS movie_title,
    t.production_year,
    COUNT(DISTINCT ah.actor_id) AS actor_count,
    STRING_AGG(DISTINCT ah.actor_name, ', ') AS actors,
    COALESCE(mi.info, 'N/A') AS movie_info,
    (SELECT COUNT(DISTINCT kc.keyword) 
     FROM movie_keyword mk
     JOIN keyword kc ON mk.keyword_id = kc.id
     WHERE mk.movie_id = t.id) AS keyword_count
FROM title t
LEFT JOIN complete_cast cc ON t.id = cc.movie_id
LEFT JOIN actor_hierarchy ah ON t.id = ah.movie_id
LEFT JOIN movie_info mi ON t.id = mi.movie_id AND mi.info_type_id IN (
    SELECT id FROM info_type WHERE info = 'Synopsis'
)
GROUP BY t.id, t.title, t.production_year, mi.info
ORDER BY movie_title ASC, production_year DESC;
This query does the following:

1. **Recursive CTE**: It constructs a hierarchy of actors for the movies they participated in, retrieving not only the actor's ID and name but also the movie ID for hierarchy building.
  
2. **Main Select**: It retrieves movie titles and their production years alongside actor counts derived from the hierarchy. The use of `STRING_AGG` allows a concatenated list of actors for each movie.

3. **Left Joins**: It performs Left Joins on the `complete_cast`, `actor_hierarchy`, and `movie_info` tables to ensure that the movies are listed even if there are no associated actors or additional information.

4. **Subquery**: The `keyword_count` subquery counts distinct keywords associated with each movie while keeping the main query clean and performant.

5. **NULL Logic**: The use of `COALESCE` ensures that if there's no synopsis available in `movie_info`, it defaults to 'N/A'.

6. **Grouping and Ordering**: It groups by movie fields to aggregate actor data and sorts the result by movie title and production year. 

This comprehensive approach provides insight into the movie landscape, highlighting what actors are involved, pertinent information, and an aesthetic order of presentation.
