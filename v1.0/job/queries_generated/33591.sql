WITH RECURSIVE movie_series AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.season_nr,
        t.episode_nr,
        t.episode_of_id,
        1 AS depth
    FROM 
        aka_title t
    WHERE 
        t.episode_of_id IS NULL

    UNION ALL

    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.season_nr,
        t.episode_nr,
        t.episode_of_id,
        ms.depth + 1
    FROM 
        aka_title t
    JOIN 
        movie_series ms ON t.episode_of_id = ms.movie_id
)

SELECT 
    mk.keyword,
    COUNT(DISTINCT c.person_id) AS actor_count,
    AVG(mi.info_length) AS avg_info_length
FROM 
    movie_keyword mk
JOIN 
    aka_title at ON mk.movie_id = at.id
LEFT JOIN 
    cast_info c ON at.id = c.movie_id
LEFT JOIN (
    SELECT 
        movie_id, 
        LENGTH(info) AS info_length
    FROM 
        movie_info
    WHERE 
        note IS NOT NULL
) mi ON at.id = mi.movie_id
LEFT JOIN 
    movie_series ms ON at.id = ms.movie_id
WHERE 
    at.production_year >= 2000
    AND (ms.depth IS NULL OR ms.depth < 5)
GROUP BY 
    mk.keyword
HAVING 
    COUNT(DISTINCT c.person_id) > 10
ORDER BY 
    actor_count DESC
LIMIT 10;

### Explanation of the Query Constructs
- **Recursive CTE (`WITH RECURSIVE movie_series`)**: This CTE helps to find all related episodes and their hierarchy in a series.
- **`LEFT JOIN`**: Utilized to include all titles from `aka_title`, including those without a corresponding entry in `cast_info`.
- **`COUNT(DISTINCT c.person_id)`**: Counts unique actors linked to movies filtered by production year.
- **Subquery (`LEFT JOIN (SELECT ...) mi`)**: Captures the average length of info entries where the note is not null.
- **Complex predicates**: The query filters based on the production year and checks if the movie is part of a series with less than 5 depth levels in the CTE.
- **`HAVING` clause**: To enforce a minimum count of actors for the keywords being retrieved.
- **Ordering and limiting**: Returns the top 10 keywords with the highest actor counts.

This query can serve as an excellent benchmark for assessing performance with its complexity and the variety of SQL techniques used.
