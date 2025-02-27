WITH RECURSIVE ActorHierarchy AS (
    SELECT ci.person_id, 
           a.name AS actor_name, 
           0 AS level
    FROM cast_info ci
    JOIN aka_name a ON ci.person_id = a.person_id
    WHERE ci.movie_id IN (SELECT id FROM aka_title WHERE production_year >= 2000)
    
    UNION ALL

    SELECT ci.person_id, 
           a.name AS actor_name, 
           ah.level + 1
    FROM cast_info ci
    JOIN aka_name a ON ci.person_id = a.person_id
    JOIN ActorHierarchy ah ON ci.movie_id = ah.person_id
),

MovieStats AS (
    SELECT at.id AS movie_id,
           at.title AS movie_title,
           COUNT(DISTINCT ci.person_id) AS total_cast,
           COUNT(DISTINCT mk.keyword) AS keyword_count
    FROM aka_title at
    LEFT JOIN cast_info ci ON at.id = ci.movie_id
    LEFT JOIN movie_keyword mk ON at.id = mk.movie_id
    WHERE at.production_year >= 2000
    GROUP BY at.id, at.title
),

DirectorStats AS (
    SELECT mc.movie_id,
           COUNT(DISTINCT mc.company_id) AS total_companies,
           STRING_AGG(DISTINCT cn.name, ', ') AS company_names
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    GROUP BY mc.movie_id
)

SELECT ms.movie_id,
       ms.movie_title,
       ms.total_cast,
       ms.keyword_count,
       ds.total_companies,
       ds.company_names,
       ah.actor_name AS cast_member,
       ah.level AS hierarchy_level
FROM MovieStats ms
LEFT JOIN DirectorStats ds ON ms.movie_id = ds.movie_id
LEFT JOIN ActorHierarchy ah ON ms.movie_id = ah.person_id
WHERE ms.keyword_count > 3
ORDER BY ms.total_cast DESC, ds.total_companies DESC, ah.level ASC
LIMIT 10;

### Explanation:
1. **Recursive CTE (`ActorHierarchy`)**: This CTE builds a hierarchy of actors by traversing their relationships in a recursive way, enabling the exploration of multi-level connections.
2. **Aggregate Data CTE (`MovieStats`)**: This CTE computes total cast size and the number of keywords for movies released after the year 2000.
3. **Company Statistics CTE (`DirectorStats`)**: This CTE aggregates statistics about the production companies involved in each movie.
4. **Main Query**: The final SELECT statement combines the results of the previous CTEs, filtering for movies with more than 3 keywords, and orders the results based on the total cast size and total companies associated with each movie. The query also limits the results to the top 10 entries.
5. **LEFT JOINs**: Used for optional data inclusion, ensuring that if a movie has no associated companies or actors, it will still be included in the results.

This query is designed to provide robust performance metrics and insights about movies, their cast, and their production backgrounds.
