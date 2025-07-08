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
        mt.production_year IS NOT NULL
    
    UNION ALL
    
    SELECT 
        mh.movie_id,
        mt.title,
        mt.production_year,
        ml.linked_movie_id,
        mh.level + 1
    FROM 
        movie_hierarchy mh
    JOIN 
        movie_link ml ON mh.linked_movie_id = ml.movie_id
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.id
    WHERE 
        mh.level < 5
),
title_info AS (
    SELECT 
        t.title,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        AVG(CASE WHEN ci.nr_order IS NOT NULL THEN ci.nr_order ELSE 0 END) AS avg_order
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON ci.movie_id = t.id
    WHERE 
        t.production_year = (SELECT MAX(production_year) FROM aka_title)
    GROUP BY 
        t.title
),
keyword_info AS (
    SELECT 
        kt.keyword,
        COUNT(mk.movie_id) AS movie_count
    FROM 
        keyword kt
    LEFT JOIN 
        movie_keyword mk ON kt.id = mk.keyword_id
    GROUP BY 
        kt.keyword
    HAVING 
        COUNT(mk.movie_id) > 5
),
company_summary AS (
    SELECT 
        c.name AS company_name,
        COUNT(mc.movie_id) AS movies_produced
    FROM 
        company_name c
    LEFT JOIN 
        movie_companies mc ON c.id = mc.company_id
    WHERE 
        c.country_code IS NOT NULL
    GROUP BY 
        c.name
    HAVING 
        COUNT(mc.movie_id) > 10
)
SELECT 
    th.title,
    th.cast_count,
    th.avg_order,
    kw.keyword,
    kw.movie_count,
    cs.company_name,
    cs.movies_produced
FROM 
    title_info th
JOIN 
    keyword_info kw ON th.cast_count > 10
LEFT JOIN 
    company_summary cs ON cs.movies_produced > th.cast_count
WHERE 
    th.avg_order IS NOT NULL
ORDER BY 
    th.cast_count DESC, cs.movies_produced ASC
LIMIT 50;
