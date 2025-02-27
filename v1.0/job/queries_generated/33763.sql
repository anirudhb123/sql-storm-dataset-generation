WITH RECURSIVE movie_hierarchy AS (
    SELECT mt.id AS movie_id, mt.title, mt.production_year, 1 AS level
    FROM aka_title mt
    WHERE mt.production_year IS NOT NULL
    
    UNION ALL
    
    SELECT mt.id, mt.title, mt.production_year, mh.level + 1
    FROM aka_title mt
    JOIN movie_link ml ON mt.id = ml.linked_movie_id
    JOIN movie_hierarchy mh ON ml.movie_id = mh.movie_id
),
cast_details AS (
    SELECT c.movie_id, c.person_id, a.name, r.role, 
           ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS actor_order
    FROM cast_info c
    JOIN aka_name a ON c.person_id = a.person_id
    JOIN role_type r ON c.role_id = r.id
),
company_details AS (
    SELECT mc.movie_id, cn.name AS company_name, ct.kind AS company_type
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    JOIN company_type ct ON mc.company_type_id = ct.id
)
SELECT mh.movie_id, mh.title, mh.production_year,
       COALESCE(cd.actor_order, 0) AS actor_count,
       GROUP_CONCAT(DISTINCT cd.name ORDER BY cd.actor_order) AS actor_names,
       GROUP_CONCAT(DISTINCT CONCAT(cd.name, ' (', ct.company_type, ')') ORDER BY ct.company_name) AS production_companies
FROM movie_hierarchy mh
LEFT JOIN cast_details cd ON mh.movie_id = cd.movie_id
LEFT JOIN company_details ct ON mh.movie_id = ct.movie_id
GROUP BY mh.movie_id, mh.title, mh.production_year
HAVING COUNT(DISTINCT cd.person_id) > 3
ORDER BY mh.production_year DESC, mh.title;

This SQL query achieves the following:

1. **Recursive CTE (`movie_hierarchy`)**: It builds a hierarchy of movies that are connected through links, getting the initial movies that have a production year and recursively joining on the `movie_link` table. 

2. **Details CTE (`cast_details`)**: This part retrieves cast members, their roles, and assigns them an order based on their appearance in a movie using `ROW_NUMBER()`.

3. **Company Details CTE (`company_details`)**: It gathers the production companies associated with each movie, joining company name and type details.

4. **Main Query**: The core query selects from the hierarchy of movies, left joining the cast and company details. It utilizes `GROUP_CONCAT` to collate the names of actors and companies, while leveraging `COALESCE` to handle cases where there may be no actors. 

5. **Predicates and Aggregation**: The HAVING clause filters out movies that have three or fewer actors, ensuring that only films with a substantial cast appear in the results.

6. **Ordering**: Finally, results are ordered first by production year in descending order and then by title, highlighting the most recent films first. 

Overall, the query reflects a complex structure leveraging various SQL constructs while extracting valuable insights from the dataset.
