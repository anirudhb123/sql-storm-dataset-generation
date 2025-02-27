WITH RECURSIVE movie_hierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM
        aka_title mt
    WHERE
        mt.kind_id = (SELECT MIN(id) FROM kind_type WHERE kind = 'movie')
        AND mt.production_year >= 2000
        
    UNION ALL

    SELECT
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM
        movie_link ml
    JOIN
        aka_title at ON ml.movie_id = at.id
    JOIN
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    WHERE
        mh.level < 5
)

SELECT
    ak.name AS actor_name,
    mt.title AS movie_title,
    mh.production_year,
    COUNT(DISTINCT c.role_id) AS total_roles,
    AVG(EXTRACT(YEAR FROM CURRENT_DATE) - mh.production_year) AS avg_age_of_movies,
    STRING_AGG(DISTINCT ik.keyword || ' (' || ik.id || ')', ', ') AS movie_keywords,
    CASE 
        WHEN COUNT(DISTINCT c.role_id) = 0 THEN 'No roles'
        ELSE 'Has roles'
    END AS role_presence,
    ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY COUNT(DISTINCT c.role_id) DESC) AS rank
FROM
    movie_hierarchy mh
JOIN
    complete_cast cc ON mh.movie_id = cc.movie_id
JOIN
    cast_info c ON cc.subject_id = c.person_id
JOIN
    aka_name ak ON c.person_id = ak.person_id
JOIN
    movie_keyword mk ON mh.movie_id = mk.movie_id
JOIN
    keyword ik ON mk.keyword_id = ik.id
LEFT JOIN
    movie_info mi ON mh.movie_id = mi.movie_id 
    AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Description')
WHERE
    ak.name IS NOT NULL
GROUP BY
    ak.name, mt.id, mh.production_year
HAVING
    AVG(EXTRACT(YEAR FROM CURRENT_DATE) - mh.production_year) > 15
ORDER BY
    mh.production_year DESC, total_roles DESC
LIMIT 100;

### Explanation:
- **CTE (Common Table Expression)**: A recursive CTE is utilized to build a hierarchy of movies based on their linked relationships, stopping after 5 levels deep.
- **Joins**: The query incorporates various tables, including `complete_cast`, `cast_info`, `aka_name`, `movie_keyword`, and `keyword` to link actors to movies and their roles effectively.
- **Aggregate Functions**: `COUNT` counts distinct roles per actor, while `AVG` calculates the average age of movies in the hierarchy.
- **String Aggregation**: `STRING_AGG` creates a list of keywords related to each movie for a comprehensive overview.
- **NULL Logic**: The `CASE` statement is used to deal with the presence of roles, differentiating between actors with and without roles.
- **Window Functions**: `ROW_NUMBER()` provides a ranking of the total roles per year, allowing for easy ordering and comparison.
- **Complicated Predicate**: The `HAVING` clause ensures that only movies older than 15 years on average are included in the final results.
- **Obscure Semantics**: The use of subqueries in the `SELECT` and joins with conditions based on potentially NULL info types illustrate an interesting yet complex SQL construction that challenges typical querying practices.
