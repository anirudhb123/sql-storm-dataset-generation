WITH RECURSIVE movie_hierarchy AS (
    SELECT m.id AS movie_id, m.title, m.production_year, 0 AS depth
    FROM aka_title m
    WHERE m.production_year IS NOT NULL

    UNION ALL

    SELECT m.id, m.title, m.production_year, mh.depth + 1
    FROM aka_title m 
    JOIN movie_link ml ON ml.movie_id = m.id
    JOIN movie_hierarchy mh ON mh.movie_id = ml.linked_movie_id
)

, actor_role_summary AS (
    SELECT 
        c.person_id,
        COUNT(DISTINCT c.movie_id) AS total_movies,
        SUM(CASE WHEN r.role = 'lead' THEN 1 ELSE 0 END) AS lead_roles
    FROM cast_info c
    JOIN role_type r ON c.role_id = r.id
    GROUP BY c.person_id
)

, movie_company_info AS (
    SELECT 
        m.id AS movie_id,
        COALESCE(c.name, 'Unknown') AS company_name, 
        COUNT(mc.company_type_id) AS company_count
    FROM movie_companies mc
    LEFT JOIN company_name c ON mc.company_id = c.id
    JOIN aka_title m ON m.id = mc.movie_id
    GROUP BY m.id, c.name
)

SELECT 
    a.name AS actor_name,
    COUNT(DISTINCT c.movie_id) AS movie_count,
    SUM(CASE WHEN r.role IS NOT NULL THEN 1 ELSE 0 END) AS roles_count,
    MAX(CASE WHEN m.production_year > 2000 THEN m.title END) AS latest_movie,
    CONCAT_WS(' & ', STRING_AGG(DISTINCT co.company_name, ', ')) AS companies_involved,
    mh.depth AS movie_depth
FROM aka_name a
JOIN cast_info c ON a.person_id = c.person_id
LEFT JOIN role_type r ON c.role_id = r.id
JOIN movie_hierarchy mh ON c.movie_id = mh.movie_id
LEFT JOIN movie_company_info co ON mh.movie_id = co.movie_id
GROUP BY a.id, mh.depth
HAVING COUNT(DISTINCT c.movie_id) > 5
ORDER BY movie_count DESC, latest_movie DESC
LIMIT 10;

### Explanation:
1. **CTEs**: 
   - **movie_hierarchy**: A recursive CTE that generates movie hierarchies based on linked movies.
   - **actor_role_summary**: Summarizes the roles of actors, counting total movies and lead roles.
   - **movie_company_info**: Collects information about companies involved in producing each movie.

2. **SELECT Statement**: 
   - The main query selects actor names and aggregates data such as movie count, roles, and the latest movie from 2000 onwards.

3. **LEFT JOINs and COALESCE**: This is used to handle scenarios where companies may not be present, allowing it to output 'Unknown' when no companies are associated.

4. **HAVING Clause**: Filters actors who have appeared in more than five movies.

5. **STRING_AGG**: Used for aggregating company names involved with movies.

This query not only explores multiple SQL features but also digs into the relationships among movies, actors, and production companies, using both joins and aggregates to showcase the data intricacies effectively.
