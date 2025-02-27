WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        CAST(NULL AS TEXT) AS parent_movie_title,
        0 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL
        
    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        mh.movie_title AS parent_movie_title,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        title t ON ml.linked_movie_id = t.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
),
actor_movie_counts AS (
    SELECT 
        ci.person_id,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.person_id
),
movie_info_filtered AS (
    SELECT 
        mi.movie_id,
        STRING_AGG(mi.info, ', ') AS info_details
    FROM 
        movie_info mi
    WHERE 
        mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'Review')
    GROUP BY 
        mi.movie_id
)
SELECT 
    ah.id AS actor_id,
    a.name AS actor_name,
    mh.movie_title,
    mh.production_year,
    mh.parent_movie_title,
    mh.level,
    COALESCE(mif.info_details, 'No reviews available') AS reviews,
    ac.movie_count
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    movie_hierarchy mh ON ci.movie_id = mh.movie_id
LEFT JOIN 
    movie_info_filtered mif ON mh.movie_id = mif.movie_id
JOIN 
    actor_movie_counts ac ON a.person_id = ac.person_id
WHERE 
    mh.level = 0
    AND mh.production_year BETWEEN 2000 AND 2020
ORDER BY 
    ac.movie_count DESC, mh.production_year DESC;
