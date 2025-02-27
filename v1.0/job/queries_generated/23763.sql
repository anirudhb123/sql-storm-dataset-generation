WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        0 AS level,
        CAST(mt.title AS VARCHAR(255)) AS path
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL
    
    UNION ALL
    
    SELECT 
        mm.id,
        mm.title,
        mh.level + 1,
        CAST(mh.path || ' -> ' || mm.title AS VARCHAR(255))
    FROM 
        movie_link ml
    JOIN 
        aka_title mm ON ml.linked_movie_id = mm.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
),

cast_summary AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS cast_with_notes
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),

keyword_summary AS (
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

movie_details AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.level,
        mh.path,
        cs.total_cast,
        cs.cast_with_notes,
        ks.keywords
    FROM 
        movie_hierarchy mh
    LEFT JOIN 
        cast_summary cs ON mh.movie_id = cs.movie_id
    LEFT JOIN 
        keyword_summary ks ON mh.movie_id = ks.movie_id
)

SELECT 
    md.movie_id,
    md.title,
    md.level,
    md.path,
    COALESCE(md.total_cast, 0) AS total_cast,
    COALESCE(md.cast_with_notes, 0) AS cast_with_notes,
    COALESCE(md.keywords, 'No Keywords') AS keywords,
    CASE 
        WHEN md.level > 0 THEN 'Linked Movie'
        ELSE 'Standalone Movie'
    END AS movie_type
FROM 
    movie_details md
WHERE 
    md.total_cast IS NOT NULL
    AND md.keywords IS NOT NULL
ORDER BY 
    md.level, 
    md.title ASC;

-- Performance benchmarking flags and necessary semantical corner cases
-- To evaluate performance, consider adding additional executions with varying WHERE clauses, 
-- and combining with indexes on relevant attributes (e.g., movie_id, person_id) and analyzing 
-- the query plan to understand the impact of joins, CTEs, and aggregations.
