WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.title,
        m.id AS movie_id,
        m.production_year,
        0 AS level
    FROM 
        aka_title m
    WHERE 
        m.kind_id IN (1, 2) -- Assuming kind_id 1, 2 corresponds to Feature and Short films
    UNION ALL
    SELECT 
        m.title,
        m.id,
        m.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
    WHERE 
        mh.level < 3 -- Limit levels (for example, to 3 for simplicity)
),
cast_roles AS (
    SELECT 
        c.movie_id,
        r.role,
        COUNT(c.person_id) AS num_actors
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.movie_id, r.role
),
movie_keyword_count AS (
    SELECT 
        mk.movie_id,
        COUNT(DISTINCT k.keyword) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
movie_info_details AS (
    SELECT 
        mi.movie_id,
        MAX(CASE WHEN it.info = 'Budget' THEN mi.info ELSE NULL END) AS budget,
        MAX(CASE WHEN it.info = 'Box Office' THEN mi.info ELSE NULL END) AS box_office
    FROM 
        movie_info mi
    JOIN 
        info_type it ON mi.info_type_id = it.id
    GROUP BY 
        mi.movie_id
)
SELECT 
    m.title,
    m.production_year,
    COALESCE(mk.keyword_count, 0) AS total_keywords,
    COALESCE(cr.num_actors, 0) AS total_actors,
    COALESCE(mid.budget, 'Unknown') AS budget,
    COALESCE(mid.box_office, 'Unknown') AS box_office
FROM 
    movie_hierarchy m
LEFT JOIN 
    movie_keyword_count mk ON m.movie_id = mk.movie_id
LEFT JOIN 
    cast_roles cr ON m.movie_id = cr.movie_id
LEFT JOIN 
    movie_info_details mid ON m.movie_id = mid.movie_id
ORDER BY 
    m.production_year DESC, 
    m.title;
