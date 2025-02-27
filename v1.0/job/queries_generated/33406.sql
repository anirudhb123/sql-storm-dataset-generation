WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        1 AS level,
        t.title,
        t.production_year
    FROM 
        aka_title AS t
    JOIN 
        movie_companies AS mc ON t.id = mc.movie_id
    WHERE 
        t.production_year IS NOT NULL
    
    UNION ALL
    
    SELECT 
        mh.movie_id,
        mh.level + 1,
        m.title,
        m.production_year
    FROM 
        movie_hierarchy AS mh
    JOIN 
        movie_link AS ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title AS m ON ml.linked_movie_id = m.id
    WHERE 
        mh.level < 3
),
cast_summary AS (
    SELECT 
        c.movie_id,
        COUNT(c.person_id) AS total_cast,
        AVG(cl.nr_order) AS average_order
    FROM 
        cast_info AS c
    JOIN 
        role_type AS r ON c.role_id = r.id
    LEFT JOIN 
        comp_cast_type AS cct ON c.person_role_id = cct.id
    WHERE 
        r.role IS NOT NULL
    GROUP BY 
        c.movie_id
),
keyword_summary AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword AS mk
    JOIN 
        keyword AS k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    COALESCE(cs.total_cast, 0) AS total_cast,
    COALESCE(cs.average_order, 0.0) AS average_order,
    COALESCE(ks.keywords, 'No Keywords') AS keywords,
    CASE 
        WHEN mh.level = 1 THEN 'Original'
        WHEN mh.level = 2 THEN 'Sequel'
        ELSE 'Related'
    END AS movie_type
FROM 
    movie_hierarchy AS mh
LEFT JOIN 
    cast_summary AS cs ON mh.movie_id = cs.movie_id
LEFT JOIN 
    keyword_summary AS ks ON mh.movie_id = ks.movie_id
ORDER BY 
    mh.production_year DESC, mh.movie_id
FETCH FIRST 50 ROWS ONLY;
