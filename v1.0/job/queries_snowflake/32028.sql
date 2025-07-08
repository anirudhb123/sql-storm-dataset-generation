WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        ml.linked_movie_id,
        1 AS level
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_link ml ON mt.id = ml.movie_id
    WHERE 
        ml.link_type_id = (SELECT id FROM link_type WHERE link = 'sequel')

    UNION ALL

    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        ml.linked_movie_id,
        mh.level + 1 AS level
    FROM 
        movie_hierarchy mh
    JOIN 
        aka_title mt ON mh.linked_movie_id = mt.id
    LEFT JOIN 
        movie_link ml ON mt.id = ml.movie_id
    WHERE 
        ml.link_type_id = (SELECT id FROM link_type WHERE link = 'sequel')
),
movie_info_summary AS (
    SELECT 
        m.id AS movie_id,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count,
        AVG(CASE WHEN mi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating') THEN CAST(mi.info AS FLOAT) END) AS average_rating
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        movie_info mi ON m.id = mi.movie_id
    GROUP BY 
        m.id
),
cast_stats AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        MIN(CASE WHEN r.role = 'lead' THEN ci.nr_order END) AS lead_order,
        MAX(CASE WHEN r.role = 'lead' THEN ci.nr_order END) AS last_lead_order
    FROM 
        cast_info ci
    JOIN 
        role_type r ON ci.role_id = r.id
    GROUP BY 
        ci.movie_id
)

SELECT 
    a.title AS movie_title,
    a.production_year,
    coalesce(b.keyword_count, 0) AS total_keywords,
    coalesce(b.average_rating, 0) AS avg_rating,
    coalesce(c.cast_count, 0) AS unique_cast_count,
    c.lead_order,
    c.last_lead_order,
    mh.level AS sequel_level
FROM 
    aka_title a
LEFT JOIN 
    movie_info_summary b ON a.id = b.movie_id
LEFT JOIN 
    cast_stats c ON a.id = c.movie_id
LEFT JOIN 
    movie_hierarchy mh ON a.id = mh.movie_id
WHERE 
    a.production_year BETWEEN 2000 AND 2023
ORDER BY 
    a.production_year DESC, a.title;
