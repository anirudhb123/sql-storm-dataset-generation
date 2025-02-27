WITH RECURSIVE movie_hierarchy AS (
    -- CTE to build a hierarchy of movies based on linked movies
    SELECT 
        m.id AS movie_id,
        m.title,
        0 AS level
    FROM 
        aka_title AS m
    WHERE 
        m.id IS NOT NULL 

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        m.title,
        mh.level + 1
    FROM 
        movie_link AS ml
    INNER JOIN
        aka_title AS m ON ml.linked_movie_id = m.id
    INNER JOIN
        movie_hierarchy AS mh ON ml.movie_id = mh.movie_id
),

-- CTE to calculate the average cast members by movie type
avg_cast_by_type AS (
    SELECT 
        ki.kind AS movie_kind,
        COUNT(DISTINCT ci.person_id) * 1.0 / NULLIF(COUNT(DISTINCT ti.id), 0) AS avg_cast_count
    FROM 
        aka_title AS ti 
    LEFT JOIN 
        cast_info AS ci ON ti.id = ci.movie_id
    INNER JOIN 
        kind_type AS ki ON ti.kind_id = ki.id
    GROUP BY 
        ki.kind
)

SELECT 
    mh.movie_id,
    mh.title,
    mh.level,
    ki.kind AS movie_type,
    COALESCE(ac.avg_cast_count, 0) AS average_cast,
    CASE 
        WHEN ac.avg_cast_count IS NOT NULL THEN 
            CASE 
                WHEN ac.avg_cast_count > 5 THEN 'Somewhat Popular'
                WHEN ac.avg_cast_count BETWEEN 2 AND 5 THEN 'Moderately Popular'
                ELSE 'Less Popular'
            END
        ELSE 'No Data'
    END AS popularity_desc
FROM 
    movie_hierarchy AS mh
LEFT JOIN 
    avg_cast_by_type AS ac ON mh.movie_id = ac.movie_kind
LEFT JOIN 
    aka_title AS a ON mh.movie_id = a.id
LEFT JOIN 
    kind_type AS ki ON a.kind_id = ki.id
WHERE 
    mh.level <= 2  -- Limit the depth of the hierarchy
ORDER BY 
    mh.level, popularity_desc, mh.title
LIMIT 100;

This query features:
- A recursive CTE (`movie_hierarchy`) to explore movie dependencies through linked movies.
- Another CTE (`avg_cast_by_type`) to calculate the average number of cast members for each movie type.
- A main SELECT statement that joins both CTEs while also handling nulls and non-existent data carefully by using `COALESCE`.
- A complex CASE statement to categorize the popularity of each movie based on average cast size.
- Filtering by hierarchy level and an order by clause for organized results.
