WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        title.id AS movie_id,
        title.title,
        title.production_year,
        NULL::text AS parent_title,
        1 AS depth
    FROM 
        title
    WHERE 
        title.production_year IS NOT NULL
    
    UNION ALL
    
    SELECT 
        mt.linked_movie_id,
        t.title,
        t.production_year,
        mh.title AS parent_title,
        mh.depth + 1
    FROM 
        movie_link mt
    JOIN 
        MovieHierarchy mh ON mt.movie_id = mh.movie_id
    JOIN 
        title t ON t.id = mt.linked_movie_id
    WHERE 
        mh.depth < 5
),
TopMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        mh.parent_title,
        mh.depth,
        ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY mh.depth DESC) AS rank
    FROM 
        MovieHierarchy mh
)
SELECT 
    DISTINCT 
    t.title AS child_movie_title,
    t.production_year AS child_movie_year,
    t.parent_title AS linked_movie_title,
    (SELECT 
        COUNT(DISTINCT ci.person_id) 
     FROM 
        cast_info ci 
     WHERE 
        ci.movie_id = t.movie_id) AS total_cast,
    COALESCE(cn.name, 'Unknown') AS production_company,
    CASE 
        WHEN t.depth <= 2 THEN 'Top Tier'
        ELSE 'Lower Tier'
    END AS tier,
    COUNT(DISTINCT mk.keyword) AS keyword_count
FROM 
    TopMovies t
LEFT JOIN 
    movie_companies mc ON mc.movie_id = t.movie_id
LEFT JOIN 
    company_name cn ON cn.id = mc.company_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = t.movie_id
WHERE 
    t.rank <= 5
GROUP BY 
    t.title, t.production_year, t.parent_title, cn.name, t.depth
HAVING 
    COUNT(DISTINCT mk.keyword) > 0
ORDER BY 
    t.production_year DESC, t.depth, total_cast DESC;

This SQL query does the following:

1. It uses a **recursive common table expression (CTE)** to build a hierarchy of movies based on linked relationships found in the `movie_link` table. The hierarchy captures the depth of linked movies up to 5 levels.
   
2. The second CTE, **TopMovies**, selects distinct movies and ranks them by their **production year** with an additional depth criteria.

3. The main query extracts **child movie details**, including the total cast count, the production company (with NULL handling), a tier categorization based on depth, and a count of keywords associated with each movie.

4. **LEFT JOINS** are utilized for optional relationships and NULL logic ensures that titles without associated companies are handled gracefully.

5. A **GROUP BY** clause groups results by relevant columns, while the **HAVING** clause filters out movies with no associated keywords.

6. Finally, results are ordered by production year in descending order, followed by depth and total cast count.

This query efficiently benchmarks the schema's performance while showcasing complex SQL constructs including joins, CTEs, window functions, NULL handling, and aggregations.
