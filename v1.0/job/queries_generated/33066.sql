WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        m.kind_id,
        CAST(NULL AS text) AS parent_movie_title,
        0 AS level
    FROM 
        aka_title m
    WHERE 
        m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        lt.title,
        lt.production_year,
        lt.kind_id,
        mh.title AS parent_movie_title,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title lt ON ml.linked_movie_id = lt.id
)

SELECT 
    mh.movie_id,
    mh.title AS movie_title,
    mh.production_year,
    mh.kind_id,
    mh.parent_movie_title,
    mh.level,
    COALESCE(gc.group_count, 0) AS group_count,
    ARRAY_AGG(DISTINCT CONCAT(a.name, ' (', r.role, ')') ORDER BY a.name) AS cast_info
FROM 
    movie_hierarchy mh
LEFT JOIN 
    (SELECT 
        ml.movie_id,
        COUNT(DISTINCT c.person_id) AS group_count
    FROM 
        movie_companies ml
    JOIN 
        company_name co ON ml.company_id = co.id
    WHERE 
        co.country_code = 'USA'
    GROUP BY 
        ml.movie_id) gc ON mh.movie_id = gc.movie_id
LEFT JOIN 
    cast_info c ON mh.movie_id = c.movie_id
LEFT JOIN 
    aka_name a ON c.person_id = a.person_id
LEFT JOIN 
    role_type r ON c.role_id = r.id
WHERE 
    mh.production_year >= 2000
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, mh.kind_id, mh.parent_movie_title, mh.level, gc.group_count
ORDER BY 
    mh.production_year DESC, mh.level, mh.title;

