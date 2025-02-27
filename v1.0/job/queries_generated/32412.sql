WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS depth,
        ARRAY[mt.id] AS path
    FROM 
        aka_title mt
    WHERE 
        mt.episode_of_id IS NULL
    
    UNION ALL

    SELECT 
        et.id AS movie_id,
        et.title,
        et.production_year,
        mh.depth + 1,
        mh.path || et.id
    FROM 
        aka_title et
    INNER JOIN 
        movie_hierarchy mh ON et.episode_of_id = mh.movie_id
),
movie_details AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COALESCE(COUNT(DISTINCT ci.person_id), 0) AS cast_count,
        COUNT(DISTINCT mk.keyword) AS keyword_count,
        ARRAY_AGG(DISTINCT c.name) AS companies,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.title) AS year_rank
    FROM 
        aka_title m
    LEFT JOIN 
        cast_info ci ON ci.movie_id = m.id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = m.id
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = m.id
    LEFT JOIN 
        company_name c ON c.id = mc.company_id
    GROUP BY 
        m.id
),
filtered_movies AS (
    SELECT 
        md.*,
        mh.depth,
        mh.path
    FROM 
        movie_details md
    LEFT JOIN 
        movie_hierarchy mh ON md.movie_id = mh.movie_id
    WHERE 
        md.production_year >= 2000 AND
        (md.cast_count > 10 OR md.keyword_count > 5)
)
SELECT 
    f.movie_id,
    f.title,
    f.production_year,
    f.cast_count,
    f.keyword_count,
    f.companies,
    f.depth,
    f.path,
    CASE 
        WHEN f.cast_count > 20 THEN 'High'
        WHEN f.cast_count BETWEEN 11 AND 20 THEN 'Medium'
        ELSE 'Low'
    END AS popularity_rating
FROM 
    filtered_movies f
ORDER BY 
    f.production_year DESC, 
    f.title;
