WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        0 AS level,
        ARRAY[mt.id] AS movie_path
    FROM 
        aka_title mt
    WHERE 
        mt.episode_of_id IS NULL
    
    UNION ALL
    
    SELECT 
        et.id AS movie_id,
        et.title,
        et.production_year,
        et.kind_id,
        mh.level + 1 AS level,
        mh.movie_path || et.id
    FROM 
        aka_title et
    INNER JOIN 
        movie_hierarchy mh ON et.episode_of_id = mh.movie_id
)

SELECT 
    mh.title,
    mh.production_year,
    string_agg(aka.name, ', ' ORDER BY aka.name) AS actor_names,
    COUNT(DISTINCT mc.company_id) AS production_companies_count,
    COUNT(DISTINCT mk.keyword) AS unique_keywords_count,
    CASE 
        WHEN COUNT(DISTINCT mk.keyword) > 0 THEN 
            SUM(CASE 
                    WHEN mk.keyword LIKE '%action%' THEN 1 ELSE 0 
                END) / COUNT(DISTINCT mk.keyword) * 100 
        ELSE 0 
    END AS action_keyword_percentage,
    row_number() OVER (PARTITION BY mh.production_year ORDER BY mh.level, mh.title) AS movie_rank
FROM 
    movie_hierarchy mh
LEFT JOIN 
    cast_info ci ON mh.movie_id = ci.movie_id
LEFT JOIN 
    aka_name aka ON ci.person_id = aka.person_id
LEFT JOIN 
    movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
WHERE 
    mh.level = 0
GROUP BY 
    mh.movie_id, mh.title, mh.production_year
HAVING 
    COUNT(DISTINCT aka.name) > 0 
    AND COUNT(DISTINCT mc.company_id) > 3
ORDER BY 
    production_year DESC, movie_rank;

### Explanation of the Query Components:
1. **Common Table Expression (CTE)**: `movie_hierarchy` grows recursively starting from movies that are not episodes (`episode_of_id IS NULL`). It forms a hierarchy of movies, allowing us to track both regular movies and their episodes.

2. **Joins**: 
   - `LEFT JOIN` with `cast_info`, `aka_name`, `movie_companies`, and `movie_keyword` to gather related data from the multiple tables per movie.

3. **Aggregation**: 
   - `string_agg` aggregates actor names into a comma-separated list.
   - `COUNT(DISTINCT ...)` counts unique production companies and keywords for each movie.

4. **Window Function**: 
   - `row_number()` gives a rank to movies within each production year based on their level in the hierarchy.

5. **Computed Columns**: 
   - The `CASE` statement delivers a percentage of keywords related to the theme 'action', providing a nested aggregation that handles division safely by checking for zero counts.

6. **Filtering (HAVING)**: At least one actor and more than three production companies are required for movies included in the final result.

7. **Ordering**: The final results are ordered by release year in descending order and by movie rank.

This query exemplifies a complex SQL structure that leverages advanced SQL features to gather highly detailed and filtered insights about movies and their associated metadata.
