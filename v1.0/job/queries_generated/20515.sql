WITH RECURSIVE movie_hierarchy AS (
    -- This CTE fetches movies and their linked movies recursively
    SELECT 
        m.id AS movie_id, 
        m.title, 
        m.production_year, 
        ml.linked_movie_id, 
        1 AS level
    FROM 
        title m
    LEFT JOIN 
        movie_link ml ON m.id = ml.movie_id
    WHERE 
        ml.linked_movie_id IS NOT NULL

    UNION ALL

    SELECT 
        m.id AS movie_id, 
        m.title, 
        m.production_year, 
        ml.linked_movie_id, 
        mh.level + 1
    FROM 
        title m
    INNER JOIN 
        movie_link ml ON m.id = ml.movie_id
    INNER JOIN 
        movie_hierarchy mh ON mh.linked_movie_id = m.id
), role_statistics AS (
    -- This CTE gathers role counts per movie with different status, joining cast info
    SELECT 
        ci.movie_id, 
        rt.role, 
        COUNT(*) AS role_count
    FROM 
        cast_info ci
    INNER JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        ci.movie_id, rt.role
),
keyword_aggregation AS (
    -- This aggregates keywords with a weird twist using NULL logic
    SELECT 
        mk.movie_id, 
        STRING_AGG(CASE WHEN k.keyword IS NULL THEN 'Unknown' ELSE k.keyword END, ', ') AS all_keywords
    FROM 
        movie_keyword mk
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)

SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    COALESCE(ks.all_keywords, 'No keywords') AS keywords,
    (SELECT COUNT(DISTINCT ci.person_id) 
     FROM cast_info ci 
     WHERE ci.movie_id = mh.movie_id) AS unique_cast_count,
    rs.role,
    rs.role_count,
    ROW_NUMBER() OVER (PARTITION BY mh.movie_id ORDER BY rs.role_count DESC NULLS LAST) AS role_rank
FROM 
    movie_hierarchy mh
LEFT JOIN 
    keyword_aggregation ks ON mh.movie_id = ks.movie_id
LEFT JOIN 
    role_statistics rs ON mh.movie_id = rs.movie_id
WHERE 
    mh.level <= 2  -- Limiting the depth of the hierarchy
ORDER BY 
    mh.production_year DESC, 
    mh.movie_id;
