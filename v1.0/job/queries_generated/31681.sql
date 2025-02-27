WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000
    
    UNION ALL

    SELECT 
        m.id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        aka_title m
    JOIN 
        movie_link ml ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title linked ON ml.linked_movie_id = linked.id
    JOIN 
        movie_hierarchy mh ON mh.movie_id = m.id
    WHERE 
        linked.production_year >= 2000
),

cast_summary AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    GROUP BY 
        ci.movie_id
),

movie_details AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COALESCE(cs.total_cast, 0) AS total_cast,
        COALESCE(cs.cast_names, 'N/A') AS cast_names
    FROM 
        aka_title m
    LEFT JOIN 
        cast_summary cs ON m.id = cs.movie_id
    WHERE 
        m.production_year BETWEEN 2000 AND 2023
),

final_output AS (
    SELECT 
        md.*,
        ROW_NUMBER() OVER (PARTITION BY md.production_year ORDER BY md.total_cast DESC) AS rank
    FROM 
        movie_details md
)

SELECT 
    fo.title,
    fo.production_year,
    fo.total_cast,
    fo.cast_names
FROM 
    final_output fo
WHERE 
    fo.rank <= 5
ORDER BY 
    fo.production_year DESC, fo.total_cast DESC;
