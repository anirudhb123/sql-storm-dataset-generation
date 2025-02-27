WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        m.company_id,
        c.name AS company_name,
        1 AS level
    FROM 
        aka_title t
    JOIN 
        movie_companies m ON m.movie_id = t.id
    JOIN 
        company_name c ON c.id = m.company_id
    WHERE 
        t.production_year IS NOT NULL
    
    UNION ALL
    
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        m.company_id,
        c.name AS company_name,
        mh.level + 1
    FROM 
        movie_hierarchy mh
    JOIN 
        movie_companies m ON m.movie_id = mh.movie_id
    JOIN 
        company_name c ON c.id = m.company_id
    WHERE 
        mh.level < 5 
        AND c.name IS NOT NULL
),
cast_summary AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        COUNT(DISTINCT ci.role_id) FILTER (WHERE ci.role_id IS NOT NULL) AS roles_count,
        COALESCE(STRING_AGG(DISTINCT ak.name, ', '), 'No Cast') AS cast_names
    FROM 
        cast_info ci
    LEFT JOIN 
        aka_name ak ON ak.person_id = ci.person_id
    GROUP BY 
        ci.movie_id
),
movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COALESCE(cast.total_cast, 0) AS total_cast,
        COALESCE(cast.roles_count, 0) AS roles_count,
        cast.cast_names,
        mh.company_name
    FROM 
        aka_title t
    LEFT JOIN 
        cast_summary cast ON cast.movie_id = t.id
    LEFT JOIN 
        movie_hierarchy mh ON mh.movie_id = t.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023 
        AND (mh.company_name IS NULL OR mh.company_name LIKE '%Entertainment%')
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.total_cast,
    md.roles_count,
    md.cast_names,
    md.company_name,
    ROW_NUMBER() OVER (PARTITION BY md.production_year ORDER BY md.total_cast DESC) AS cast_rank
FROM 
    movie_details md
WHERE 
    md.roles_count > 0
ORDER BY 
    md.production_year, md.total_cast DESC
LIMIT 100;

This SQL query utilizes multiple constructs including common table expressions (CTEs), recursive queries, aggregation, filtering, and window functions to benchmark performance while retrieving a complex set of data from a film industry database. It focuses on movies produced between 2000 and 2023, considering company names and the cast details for each movie, and ranks them based on the number of cast members.
