WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COALESCE(mo.linked_movie_id, -1) AS linked_movie_id,
        1 AS depth
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_link mo ON mt.id = mo.movie_id
    WHERE 
        mt.production_year >= 1990
    UNION ALL
    SELECT 
        mt1.id AS movie_id,
        mt1.title,
        mt1.production_year,
        COALESCE(mo1.linked_movie_id, -1),
        mh.depth + 1
    FROM 
        movie_hierarchy mh
    JOIN 
        aka_title mt1 ON mh.linked_movie_id = mt1.id
    LEFT JOIN 
        movie_link mo1 ON mt1.id = mo1.movie_id 
    WHERE 
        mh.depth < 5 AND 
        (mh.depth = 1 OR mh.linked_movie_id != -1)
)
SELECT 
    a.name AS actor_name,
    STRING_AGG(DISTINCT mh.title || ' (' || mh.production_year || ')', ', ') AS linked_movies,
    COUNT(DISTINCT m.title) AS movies_count,
    SUM(CASE WHEN m.production_year < 2000 THEN 1 ELSE 0 END) AS pre_2000_count,
    AVG(EXTRACT(YEAR FROM CURRENT_DATE) - m.production_year) AS avg_years_since_release,
    ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY COUNT(m.title) DESC) AS rank
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    aka_title m ON ci.movie_id = m.id
LEFT JOIN 
    movie_hierarchy mh ON m.id = mh.movie_id
WHERE 
    a.name IS NOT NULL
GROUP BY 
    a.name, a.id
HAVING 
    COUNT(m.title) > 5 AND 
    AVG(EXTRACT(YEAR FROM CURRENT_DATE) - m.production_year) < 15
ORDER BY 
    rank, movies_count DESC;

### Explanation:
- **Common Table Expression (CTE)**: The `movie_hierarchy` CTE creates a recursive structure to follow linked movies up to 5 levels deep while filtering for titles produced from 1990. This allows us to explore complex associations between movies.
- **Joins**: The query joins multiple tables to gather information about actors, cast, and titles.
- **Aggregations**: It uses `STRING_AGG` to concatenate movie titles and their years, and `COUNT`, `SUM`, and `AVG` to calculate various statistics regarding the movies they've appeared in.
- **Window Function**: `ROW_NUMBER()` is applied to rank actors based on their film count.
- **Conditions**: The `HAVING` clause filters actors who have appeared in more than 5 movies and whose average release year is within the last 15 years.
- **NULL Handling**: The `COALESCE` function is used to ensure there's a default value for linked movies. Additionally, NULL checks are included in the WHERE clause.

