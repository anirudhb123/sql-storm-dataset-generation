WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        title.title AS movie_title,
        1 AS level,
        NULL::integer AS parent_id
    FROM aka_title title
    INNER JOIN movie_companies mc ON title.id = mc.movie_id
    WHERE title.production_year >= 2000

    UNION ALL

    SELECT 
        mt.id AS movie_id,
        title.title AS movie_title,
        mh.level + 1,
        mh.movie_id AS parent_id
    FROM movie_hierarchy mh
    INNER JOIN movie_link ml ON mh.movie_id = ml.movie_id
    INNER JOIN aka_title title ON ml.linked_movie_id = title.id
)
SELECT 
    a.name AS actor_name,
    COUNT(DISTINCT c.movie_id) AS movie_count,
    AVG(m.production_year) AS avg_movie_year,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    COUNT(DISTINCT CASE WHEN ci.role_id IS NOT NULL THEN ci.movie_id END) AS roles_count,
    SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS notes_count,
    ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY COUNT(DISTINCT c.movie_id) DESC) AS actor_rank
FROM aka_name a
LEFT JOIN cast_info ci ON a.person_id = ci.person_id
LEFT JOIN complete_cast cc ON ci.movie_id = cc.movie_id
LEFT JOIN movie_keyword mk ON mk.movie_id = cc.movie_id
LEFT JOIN keyword k ON mk.keyword_id = k.id
LEFT JOIN movie_hierarchy m ON m.movie_id = cc.movie_id
GROUP BY a.name
HAVING COUNT(DISTINCT c.movie_id) > 5
ORDER BY actor_rank
LIMIT 10;

In this SQL query:

- A recursive CTE, `movie_hierarchy`, is used to create a hierarchy of movies linked together based on a linking structure. It starts from movies produced in 2000 and later, building a hierarchy of linked movies.
- The main query then fetches actor names, counts their movie appearances, computes the average production year of their movies, and aggregates keywords associated with those movies.
- A window function (`ROW_NUMBER()`) gives each actor a rank based on their number of movie appearances.
- The query filters to return only those actors who have appeared in more than 5 movies and limits the output to the top 10 actors.
- Various join types (left join) are used to accommodate situations where there may not be complete corresponding data (to handle NULLs).
