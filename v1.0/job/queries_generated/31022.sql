WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.episode_of_id IS NULL
    
    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        aka_title m
    JOIN 
        movie_hierarchy mh ON m.episode_of_id = mh.movie_id
)

SELECT 
    a.name AS actor_name,
    a.id AS actor_id,
    ARRAY_AGG(DISTINCT k.keyword) AS keywords,
    COUNT(DISTINCT mc.movie_id) AS total_movies,
    MAX(mh.production_year) AS latest_movie_year,
    AVG(mh.level) AS avg_episode_level,
    SUM(CASE WHEN mi.note IS NOT NULL THEN 1 ELSE 0 END) AS info_note_present
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    movie_companies mc ON ci.movie_id = mc.movie_id
JOIN 
    movie_info mi ON mi.movie_id = mc.movie_id
LEFT JOIN 
    movie_keyword k ON mc.movie_id = k.movie_id
LEFT JOIN 
    movie_hierarchy mh ON mc.movie_id = mh.movie_id
WHERE 
    ci.note IS NULL
    AND EXISTS (
        SELECT 1
        FROM complete_cast cc
        WHERE cc.movie_id = mc.movie_id
        AND cc.status_id = 1
    )
GROUP BY 
    a.name, a.id
HAVING 
    COUNT(DISTINCT mc.company_id) > 2
ORDER BY 
    total_movies DESC,
    actor_id ASC
LIMIT 10;

### Explanation:
- A **recursive common table expression (CTE)** named `movie_hierarchy` is used to gather a hierarchy of movies, including episodes.
- The main query joins several tables, including `aka_name`, `cast_info`, `movie_companies`, and aggregates their data.
- It uses `ARRAY_AGG` to create an array of distinct keywords for each actor, counts the total movies they are involved in, and determines the latest movie year.
- A conditional aggregation counts how many movie info notes are present for each actor.
- The query filters actors based on their role (using `WHERE` and `EXISTS` clauses).
- `HAVING` is used to ensure only actors associated with more than two companies are included.
- Finally, the results are ordered and limited to the top 10 actors based on their movie count.
