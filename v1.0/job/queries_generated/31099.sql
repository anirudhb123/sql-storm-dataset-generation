WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        COALESCE(m.production_year::TEXT, 'Unknown') AS production_year,
        NULL::TEXT AS parent_movie,
        1 AS level
    FROM title m
    WHERE m.id NOT IN (SELECT episode_of_id FROM title WHERE episode_of_id IS NOT NULL)

    UNION ALL

    SELECT 
        e.id AS movie_id,
        e.title,
        COALESCE(e.production_year::TEXT, 'Unknown') AS production_year,
        p.title AS parent_movie,
        h.level + 1 AS level
    FROM title e
    JOIN movie_hierarchy h ON e.episode_of_id = h.movie_id
    JOIN title p ON h.movie_id = p.id
)

SELECT 
    h.movie_id,
    h.title,
    h.production_year,
    h.parent_movie,
    h.level,
    ARRAY_AGG(DISTINCT a.name) AS actors,
    COUNT(DISTINCT kc.keyword) AS keyword_count
FROM 
    movie_hierarchy h
LEFT JOIN 
    complete_cast c ON h.movie_id = c.movie_id
LEFT JOIN 
    cast_info ci ON c.subject_id = ci.person_id
LEFT JOIN 
    aka_name a ON ci.person_id = a.person_id
LEFT JOIN 
    movie_keyword mk ON h.movie_id = mk.movie_id
LEFT JOIN 
    keyword kc ON mk.keyword_id = kc.id
GROUP BY 
    h.movie_id, h.title, h.production_year, h.parent_movie, h.level
ORDER BY 
    h.level DESC, h.movie_id
LIMIT 100;

This complex SQL query generates a hierarchical view of movies, including adaptations and sequels. It employs a recursive CTE to create a hierarchy of titles, joining multiple tables to gather information about cast members and keywords while applying various aggregation functions to summarize actor names and keyword counts. The results are ordered by the level of the hierarchy and limited to the top 100 entries, making it useful for performance benchmarking.
