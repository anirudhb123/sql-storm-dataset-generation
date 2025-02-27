WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.production_year > 2000  -- Focus on modern films
    UNION ALL
    SELECT 
        ml.linked_movie_id,
        m.title,
        m.production_year,
        mh.depth + 1
    FROM 
        movie_link ml
    JOIN 
        title m ON ml.linked_movie_id = m.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    WHERE 
        mh.depth < 3  -- Limit the depth of the hierarchy
),
avg_cast_roles AS (
    SELECT 
        ci.movie_id,
        COUNT(*) AS role_count,
        AVG(CASE WHEN ci.note IS NULL THEN 0 ELSE 1 END) AS null_note_percentage
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),
popular_keywords AS (
    SELECT 
        mk.movie_id,
        k.keyword,
        COUNT(mk.keyword_id) AS usage_count
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id, k.keyword
    HAVING 
        COUNT(mk.keyword_id) > 5  -- Filter keywords used frequently
)
SELECT 
    mh.title AS movie_title,
    mh.production_year,
    ac.role_count,
    ac.null_note_percentage,
    pk.keyword,
    pk.usage_count
FROM 
    movie_hierarchy mh
LEFT JOIN 
    avg_cast_roles ac ON mh.movie_id = ac.movie_id
LEFT JOIN 
    popular_keywords pk ON mh.movie_id = pk.movie_id
WHERE 
    mh.production_year BETWEEN 2010 AND 2020
ORDER BY 
    mh.production_year DESC,
    ac.role_count DESC,
    pk.usage_count DESC
LIMIT 100;  -- Performance test with a limited result set
