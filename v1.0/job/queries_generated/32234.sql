WITH RECURSIVE movie_hierarchy AS (
    -- This CTE recursively collects movies and its linked movies up to 3 degrees of separation
    SELECT 
        ml.movie_id AS root_movie_id,
        ml.linked_movie_id,
        1 AS level
    FROM 
        movie_link ml
    WHERE 
        ml.linked_movie_id IS NOT NULL

    UNION ALL

    SELECT 
        mh.root_movie_id,
        ml.linked_movie_id,
        mh.level + 1
    FROM 
        movie_hierarchy mh
    JOIN 
        movie_link ml ON mh.linked_movie_id = ml.movie_id
    WHERE 
        mh.level < 3
),

movie_keywords AS (
    -- CTE to aggregate movie keywords
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),

complete_movie_info AS (
    -- Combine movie titles, information and keywords
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COALESCE(mk.keywords, 'No Keywords') AS keywords,
        COALESCE(CAST(mi.info AS VARCHAR), 'No Info') AS additional_info
    FROM 
        title t
    LEFT JOIN 
        movie_info mi ON t.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Synopsis')
    LEFT JOIN 
        movie_keywords mk ON t.id = mk.movie_id
)

SELECT 
    cm.movie_id,
    cm.title,
    cm.production_year,
    cm.keywords,
    COALESCE(ca.original_role, 'No Role') AS cast_role,
    COUNT(DISTINCT mk.keyword_id) OVER (PARTITION BY cm.movie_id) AS keyword_count,
    AVG(CASE 
        WHEN ca.nr_order < 5 THEN 1
        ELSE 0
    END) OVER (PARTITION BY cm.movie_id) AS high_priority_cast_avg
FROM 
    complete_movie_info cm
LEFT JOIN 
    cast_info ca ON cm.movie_id = ca.movie_id
LEFT JOIN 
    aka_title at ON cm.movie_id = at.movie_id
LEFT JOIN 
    movie_hierarchy mh ON cm.movie_id = mh.root_movie_id
WHERE 
    cm.production_year > 2000
    AND (cm.keywords IS NOT NULL OR cm.additional_info IS NOT NULL)
ORDER BY 
    cm.production_year DESC,
    cm.title ASC;
