WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level,
        m.id AS root_movie_id
    FROM 
        aka_title m
    WHERE 
        m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        m.id,
        m.title,
        m.production_year,
        mh.level + 1,
        mh.root_movie_id
    FROM 
        movie_link ml
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
    WHERE 
        m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
),

movie_cast AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        c.person_id,
        a.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY m.id ORDER BY c.nr_order) AS actor_order
    FROM 
        aka_title m
    LEFT JOIN 
        cast_info c ON m.id = c.movie_id
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        m.production_year >= 2000
),

movie_info_aggregated AS (
    SELECT 
        m.id AS movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        COUNT(DISTINCT mi.info_type_id) AS info_type_count
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_info mi ON m.id = mi.movie_id
    GROUP BY 
        m.id
)

SELECT 
    mh.root_movie_id,
    mh.title,
    mh.production_year,
    mc.actor_name,
    mc.actor_order,
    mia.keywords,
    mia.info_type_count,
    COALESCE(mia.info_type_count, 0) AS total_info,
    CASE 
        WHEN mh.level > 1 THEN 'Related Movie'
        ELSE 'Root Movie'
    END AS movie_type
FROM 
    movie_hierarchy mh
JOIN 
    movie_cast mc ON mh.movie_id = mc.movie_id
JOIN 
    movie_info_aggregated mia ON mh.movie_id = mia.movie_id
WHERE 
    mh.level <= 3
ORDER BY 
    mh.production_year DESC, 
    mc.actor_order;
