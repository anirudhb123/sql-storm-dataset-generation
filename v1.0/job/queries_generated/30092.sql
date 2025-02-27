WITH RECURSIVE movie_hierarchy AS (
    SELECT mt.id AS movie_id, mt.title, mt.production_year, 0 AS level
    FROM aka_title mt
    WHERE mt.episode_of_id IS NULL
    
    UNION ALL
    
    SELECT m.id AS movie_id, m.title, m.production_year, mh.level + 1
    FROM aka_title m
    JOIN movie_link ml ON m.id = ml.linked_movie_id
    JOIN movie_hierarchy mh ON ml.movie_id = mh.movie_id
),
actor_roles AS (
    SELECT ci.movie_id, ci.person_id, ci.role_id, 
           COUNT(*) AS total_roles,
           ROW_NUMBER() OVER (PARTITION BY ci.person_id ORDER BY COUNT(*) DESC) as role_rank
    FROM cast_info ci
    GROUP BY ci.movie_id, ci.person_id, ci.role_id
),
companies_info AS (
    SELECT mc.movie_id, cn.name AS company_name, ct.kind AS company_type, COUNT(*) AS movies_count
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    GROUP BY mc.movie_id, cn.name, ct.kind
)

SELECT mh.movie_id, mh.title, mh.production_year,
       ar.person_id, a.name AS actor_name, ar.total_roles,
       ci.company_name, ci.company_type, ci.movies_count
FROM movie_hierarchy mh
LEFT JOIN actor_roles ar ON mh.movie_id = ar.movie_id AND ar.role_rank = 1
LEFT JOIN aka_name a ON ar.person_id = a.person_id
LEFT JOIN companies_info ci ON mh.movie_id = ci.movie_id
WHERE mh.production_year >= 2000
AND (ci.movies_count IS NULL OR ci.movies_count > 1)
ORDER BY mh.production_year DESC, mh.title, ar.total_roles DESC;

This SQL query performs several advanced operations including:

1. **Recursive CTE (`movie_hierarchy`)**: This is used to gather a list of movies and any linked movies, building a hierarchy of episodes.

2. **Aggregated subquery (`actor_roles`)**: Counts the number of roles per actor and assigns a rank based on the number of roles.

3. **Companies subquery (`companies_info`)**: Gathers information about movie companies, counting how many movies each company has contributed to.

4. **Outer Joins**: Joins the results from the hierarchical movies with actor roles and company information such that all movies are listed, with actors and companies matched when possible.

5. **Filtering**: The main query filters for movies produced after the year 2000, as well as ensuring that any companies listed have contributed to more than one movie OR are listed as NULL.

6. **Ordering**: Finally, the results are ordered by production year descending, then by movie title and total roles per actor, to prioritize recent movies with the most prolific actors.

Each part of the query showcases advanced SQL constructs suitable for performance benchmarking and complex data retrieval in a movie database schema.

