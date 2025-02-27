WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS depth
    FROM 
        aka_title m
    WHERE 
        m.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.depth + 1
    FROM 
        movie_link ml
    JOIN 
        movie_hierarchy mh ON ml.linked_movie_id = mh.movie_id
    JOIN 
        aka_title m ON ml.movie_id = m.id
    WHERE 
        m.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
),
actor_info AS (
    SELECT 
        a.name,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        STRING_AGG(DISTINCT at.title, ', ') AS movies
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        aka_title at ON ci.movie_id = at.id
    WHERE 
        a.name IS NOT NULL
    GROUP BY 
        a.name
),
movie_details AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        AVG(CASE WHEN mi.info_type_id IS NOT NULL THEN LENGTH(mi.info) ELSE NULL END) AS avg_info_length
    FROM 
        movie_hierarchy mh
    LEFT JOIN 
        complete_cast cc ON mh.movie_id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    LEFT JOIN 
        movie_info mi ON mh.movie_id = mi.movie_id
    GROUP BY 
        mh.movie_id, mh.title, mh.production_year
)
SELECT 
    md.title,
    md.production_year,
    md.actor_count,
    ai.movie_count AS unique_actor_movie_count,
    md.avg_info_length,
    CASE 
        WHEN md.actor_count > 10 THEN 'Large Cast'
        WHEN md.actor_count > 0 THEN 'Small Cast'
        ELSE 'No Cast'
    END AS cast_size,
    (SELECT COUNT(*) FROM aka_title WHERE production_year = md.production_year) AS movie_count_for_year
FROM 
    movie_details md
JOIN 
    actor_info ai ON md.actor_count = ai.movie_count
WHERE 
    md.avg_info_length > 100
ORDER BY 
    md.production_year DESC,
    md.actor_count DESC
LIMIT 50;
