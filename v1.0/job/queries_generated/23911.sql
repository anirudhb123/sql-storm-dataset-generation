WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id, 
        mt.title, 
        mt.production_year,
        0 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id, 
        at.title, 
        at.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)
, evaluated_cast AS (
    SELECT 
        ca.person_id, 
        ca.movie_id,
        SUM(CASE WHEN ca.note IS NOT NULL THEN 1 ELSE 0 END) AS has_note_count,
        COUNT(ca.role_id) AS total_roles,
        ROW_NUMBER() OVER (PARTITION BY ca.person_id ORDER BY COUNT(ca.role_id) DESC) AS rank
    FROM 
        cast_info ca
    WHERE 
        ca.nr_order = 1
    GROUP BY 
        ca.person_id,
        ca.movie_id
)
SELECT 
    mh.title AS movie_title,
    mh.production_year,
    ak.name AS actor_name,
    ec.has_note_count,
    ec.total_roles
FROM 
    movie_hierarchy mh
LEFT OUTER JOIN 
    evaluated_cast ec ON mh.movie_id = ec.movie_id
LEFT OUTER JOIN 
    aka_name ak ON ec.person_id = ak.person_id
WHERE 
    mh.level <= 3
    AND (mh.production_year >= 2000 OR ak.name ILIKE '%Smith%')
ORDER BY 
    mh.production_year DESC,
    ec.total_roles DESC
LIMIT 50;

### Explanation
- **Common Table Expressions (CTEs)**: 
    - The `movie_hierarchy` CTE recursively retrieves movies and their linked sequels or predecessors, categorizing them by a level to conditionally filter depth.
    - The `evaluated_cast` CTE calculates role statistics for actors, counting how many notes are associated with their roles and ranking them based on the number of roles they hold.
  
- **Window Functions**: The use of `ROW_NUMBER()` allows for ranking cast members based on the number of roles per person.

- **Outer Joins**: Both `LEFT OUTER JOIN` statements ensure that movies and actors are included in the results even if there are missing relationships.

- **Predicates**: The final `WHERE` clause showcases a combination of conditions.
  - It retrieves movies linked up to three levels deep.
  - It either restricts to movies produced from 2000 onwards or includes any actors with 'Smith' in their names (a common name allowing for varied results).

- **Non-null Logic**: The `CASE` statement counts notes passed via `SUM`, cleverly handling NULL scenarios.

- **Sorting and Limiting Result Sets**: Results are ordered by `production_year` and by `total_roles` descending, capping the output to 50 records for performance benchmarking.

Overall, this query is complex, leveraging a range of SQL features while exploring potential logical corners and providing a potent basis for performance benchmarking.
