WITH RECURSIVE movie_hierarchy AS (
    -- This CTE recursively creates a hierarchy of movies and their linked counterparts
    SELECT 
        m.id AS movie_id, 
        COALESCE(ml.linked_movie_id, 0) AS linked_movie_id,
        1 AS level
    FROM 
        title m
    LEFT JOIN 
        movie_link ml ON m.id = ml.movie_id
    UNION ALL
    SELECT 
        mh.movie_id, 
        COALESCE(ml.linked_movie_id, 0), 
        mh.level + 1
    FROM 
        movie_hierarchy mh
    LEFT JOIN 
        movie_link ml ON mh.linked_movie_id = ml.movie_id
    WHERE 
        mh.level < 5  -- Limit the recursion depth to avoid infinite loops
),
cast_and_info AS (
    -- This CTE retrieves cast information along with movie details, filtering on non-null conditions
    SELECT 
        ci.movie_id,
        ci.person_id,
        t.title,
        ci.nr_order,
        COALESCE(pi.info, 'Unknown') AS person_info,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM 
        cast_info ci
    JOIN 
        title t ON ci.movie_id = t.id
    LEFT JOIN 
        person_info pi ON ci.person_id = pi.person_id AND pi.info_type_id = 1  -- Assume 1 is for certain info
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    WHERE 
        t.production_year >= 2000 
        AND ci.nr_order IS NOT NULL
    GROUP BY 
        ci.movie_id, ci.person_id, t.title, ci.nr_order, pi.info
),
ranked_cast AS (
    -- Apply window functions to rank cast members based on their order in the movie
    SELECT 
        movie_id, 
        person_id, 
        title, 
        nr_order, 
        person_info,
        keyword_count,
        RANK() OVER (PARTITION BY movie_id ORDER BY nr_order) AS role_rank
    FROM 
        cast_and_info
)
SELECT 
    m.id AS movie_id,
    m.title,
    m.production_year,
    rc.person_id,
    rc.person_info,
    rc.role_rank,
    mh.linked_movie_id,
    CASE 
        WHEN mh.linked_movie_id <> 0 THEN 'Linked'
        ELSE 'Not Linked'
    END AS link_status,
    CASE 
        WHEN rc.keyword_count IS NULL THEN 'No Keywords'
        ELSE CONCAT(rc.keyword_count, ' Keywords')
    END AS keyword_summary
FROM 
    title m
LEFT JOIN 
    ranked_cast rc ON m.id = rc.movie_id
LEFT JOIN 
    movie_hierarchy mh ON m.id = mh.movie_id
WHERE 
    (m.kind_id IS NULL OR m.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE '%Drama%'))  -- Obscure filtering
    AND (rc.role_rank <= 5 OR rc.role_rank IS NULL)  -- Only wanting top-ranked roles or those without ranking
ORDER BY 
    m.production_year DESC, m.title, rc.role_rank;
