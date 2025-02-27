WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL
        
    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title m ON m.id = ml.linked_movie_id
)
, movie_keywords AS (
    SELECT 
        m.id AS movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        aka_title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id
)
, actor_movie_counts AS (
    SELECT 
        ca.person_id,
        COUNT(DISTINCT ca.movie_id) AS movie_count
    FROM 
        cast_info ca
    GROUP BY 
        ca.person_id
)
SELECT 
    mh.movie_id, 
    mh.title, 
    mh.production_year, 
    COALESCE(mk.keywords, 'No keywords') AS keywords,
    COALESCE(COUNT(DISTINCT c.person_id) FILTER (WHERE c.note IS NULL), 0) AS unnamed_cast_count,
    AVG(CASE 
        WHEN p.gender IS NULL THEN 1.0 
        ELSE 0.0 
    END) AS unknown_gender_ratio,
    ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY mh.movie_id) AS rank_within_year,
    CASE 
        WHEN mh.level > 1 THEN 'Linked Movie'
        ELSE 'Standalone Movie'
    END AS movie_type
FROM 
    movie_hierarchy mh
LEFT JOIN 
    movie_keywords mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info c ON cc.subject_id = c.person_id
LEFT JOIN 
    person_info p ON c.person_id = p.person_id
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, mk.keywords, mh.level
HAVING 
    COUNT(DISTINCT c.person_id) > 0
ORDER BY 
    mh.production_year DESC, mh.title ASC
LIMIT 50 OFFSET 10;

This SQL query combines several advanced features, including recursive CTEs to manage hierarchical movie relationships, string aggregation, conditional counts using filters, and window functions to generate ranking while handling NULL values intricately. It accounts for both direct and indirect relationships among movies, and it provides insights into actor participation and gender identification issues in the system while managing corner cases effectively.
