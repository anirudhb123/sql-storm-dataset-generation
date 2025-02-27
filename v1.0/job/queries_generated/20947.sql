WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        mt.episode_of_id,
        mt.season_nr,
        mt.episode_nr,
        0 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000

    UNION ALL

    SELECT 
        ht.id,
        ht.title,
        ht.production_year,
        ht.kind_id,
        ht.episode_of_id,
        ht.season_nr,
        ht.episode_nr,
        mh.depth + 1
    FROM 
        aka_title ht
    JOIN 
        MovieHierarchy mh ON ht.episode_of_id = mh.movie_id
)

SELECT 
    mk.keyword, 
    COUNT(DISTINCT mc.movie_id) AS movie_count,
    STRING_AGG(DISTINCT mt.title, ', ' ORDER BY mt.title) AS titles,
    COALESCE(NULLIF(EXTRACT(YEAR FROM AVG(CAST(mt.production_year AS FLOAT))), 0), NULL) AS avg_production_year,
    SUM(CASE 
            WHEN mt.season_nr IS NOT NULL THEN 1 
            ELSE 0 
        END) AS total_episodes,
    COUNT(DISTINCT CASE 
            WHEN ci.person_role_id IS NULL THEN NULL 
            ELSE ci.id 
        END) AS cast_count
FROM 
    keyword mk
JOIN 
    movie_keyword mklink ON mk.id = mklink.keyword_id
JOIN 
    aka_title mt ON mklink.movie_id = mt.id
LEFT JOIN 
    complete_cast cc ON mt.id = cc.movie_id
LEFT JOIN 
    cast_info ci ON mt.id = ci.movie_id AND ci.nr_order IS NOT NULL
LEFT JOIN 
    MovieHierarchy mh ON mh.movie_id = mt.id
GROUP BY 
    mk.keyword
HAVING 
    COUNT(DISTINCT mc.movie_id) > 5 
    AND AVG(CASE WHEN mt.production_year IS NOT NULL THEN mt.production_year END) < 2020
ORDER BY 
    movie_count DESC
FETCH FIRST 10 ROWS ONLY;

### Explanation:
- **Common Table Expression (CTE)**: A recursive CTE (`MovieHierarchy`) that builds a hierarchy of movies based on episodes, allowing for nested series exploration.
- **Joins**: Utilizes various joins including LEFT JOINs to retain all movies even if there are no casts.
- **Aggregate Functions**: Counts distinct movies, averages production years while handling potential NULLs, and uses `STRING_AGG` for a concatenated list of titles.
- **Complicated Logic**: The HAVING clause includes conditions with aggregate functions to filter results based on specific criteria related to movie counts and production years.
- **Fetching Results**: Limits results to the top 10 keywords based on the number of distinct movies associated with them. 
- **NULL Handling**: Uses `COALESCE` and `NULLIF` to manage scenarios where the average might return zero or NULL values. 

This query illustrates a complex analysis that benchmarks the performance of joins and aggregates while considering movie hierarchies and various conditions.
