WITH RECURSIVE movie_hierarchy AS (
    SELECT mt.id AS movie_id, 
           mt.title, 
           mt.production_year, 
           0 AS depth,
           CAST(mt.title AS VARCHAR(255)) AS path
    FROM aka_title mt
    WHERE mt.production_year IS NOT NULL
    
    UNION ALL
    
    SELECT mk.id AS movie_id, 
           mk.title, 
           mk.production_year, 
           mh.depth + 1,
           CONCAT(mh.path, ' -> ', mk.title)
    FROM movie_link ml
    JOIN movie_hierarchy mh ON ml.movie_id = mh.movie_id
    JOIN aka_title mk ON ml.linked_movie_id = mk.id
    WHERE mh.depth < 5
),

actor_roles AS (
    SELECT ai.person_id, 
           ak.name,
           COUNT(DISTINCT ci.movie_id) AS movie_count,
           STRING_AGG(DISTINCT at.title, '; ') AS movies
    FROM cast_info ci
    JOIN aka_name ak ON ci.person_id = ak.person_id
    JOIN aka_title at ON ci.movie_id = at.id
    GROUP BY ai.person_id, ak.name
    HAVING COUNT(DISTINCT ci.movie_id) > 3
),

movies_with_keywords AS (
    SELECT mt.id AS movie_id, 
           mt.title,
           STRING_AGG(kw.keyword, ', ') AS keywords
    FROM aka_title mt
    LEFT JOIN movie_keyword mk ON mt.id = mk.movie_id
    LEFT JOIN keyword kw ON mk.keyword_id = kw.id
    GROUP BY mt.id, mt.title
)

SELECT 
    mh.path,
    mh.depth,
    ar.name AS actor_name,
    ar.movie_count,
    mwk.title AS linked_movie_title,
    mwk.keywords,
    CASE 
        WHEN ar.movie_count IS NULL THEN 'No Roles'
        WHEN mwk.keywords IS NULL THEN 'No Keywords'
        ELSE 'Movie Details Available'
    END AS details_available
FROM movie_hierarchy mh
LEFT JOIN actor_roles ar ON mh.movie_id = ar.movie_count
LEFT JOIN movies_with_keywords mwk ON mh.movie_id = mwk.movie_id
WHERE mh.production_year >= 2000
ORDER BY mh.depth, ar.movie_count DESC NULLS LAST;

### Explanation:
1. **CTE `movie_hierarchy`**: A recursive CTE to build a hierarchy of movies with a maximum depth of 5 links, showing the relationship through joined movies.

2. **CTE `actor_roles`**: Aggregates data on actors who have participated in more than three movies, combining their names and the count of movies.

3. **CTE `movies_with_keywords`**: Collects all keywords associated with each movie by joining the `aka_title`, `movie_keyword`, and `keyword` tables.

4. **Final Selection**: Combines the results to showcase the movie hierarchy alongside actor roles and keyword information, providing an ON condition for the joined tables.

5. **CASE Statement**: Demonstrates different semantic checks based on the availability of roles and keywords, applying NULL logic for scenario handling.

This query intricately intertwines multiple constructs and scenarios with an awareness of potential NULL cases and semantic overlap, making it a worthy piece for performance benchmarking in a complex schema.
