WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS depth
    FROM 
        aka_title m
    WHERE 
        m.production_year > 2000
    UNION ALL
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.depth + 1
    FROM 
        aka_title m
    JOIN 
        movie_link ml ON ml.linked_movie_id = m.id
    JOIN 
        movie_hierarchy mh ON mh.movie_id = ml.movie_id
),
cast_roles AS (
    SELECT 
        ci.movie_id,
        MAX(CASE WHEN ci.person_role_id = rt.id THEN rt.role END) AS primary_role,
        COUNT(ci.id) AS total_cast
    FROM 
        cast_info ci
    JOIN 
        role_type rt ON ci.person_role_id = rt.id
    GROUP BY 
        ci.movie_id
),
movie_info_filtered AS (
    SELECT 
        mi.movie_id,
        STRING_AGG(DISTINCT mi.info, ', ') AS all_info
    FROM 
        movie_info mi
    JOIN 
        info_type it ON mi.info_type_id = it.id
    WHERE 
        it.info LIKE '%Award%'
    GROUP BY 
        mi.movie_id
)
SELECT 
    mh.title,
    mh.production_year,
    cr.primary_role,
    cr.total_cast,
    mif.all_info
FROM 
    movie_hierarchy mh
LEFT JOIN 
    cast_roles cr ON mh.movie_id = cr.movie_id
LEFT JOIN 
    movie_info_filtered mif ON mh.movie_id = mif.movie_id
WHERE 
    cr.total_cast > 5 
    AND (mif.all_info IS NOT NULL OR cr.primary_role IS NOT NULL)
ORDER BY 
    mh.production_year DESC, 
    mh.title;
