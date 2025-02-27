WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        m2.title AS linked_title,
        ml.link_type_id
    FROM 
        aka_title m
    LEFT JOIN 
        movie_link ml ON m.id = ml.movie_id
    LEFT JOIN 
        aka_title m2 ON ml.linked_movie_id = m2.id
    WHERE 
        m.production_year > 2000

    UNION ALL

    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        m2.title AS linked_title,
        ml.link_type_id
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title m2 ON ml.linked_movie_id = m2.id
    WHERE 
        m2.production_year > 2000
),
AverageRatings AS (
    SELECT 
        title.id AS movie_id,
        AVG(rating) AS avg_rating
    FROM 
        title
    LEFT JOIN 
        movie_info mi ON title.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
    WHERE 
        mi.info IS NOT NULL
    GROUP BY 
        title.id
),
CastPersonRoles AS (
    SELECT 
        ci.movie_id,
        cr.role AS role,
        COUNT(*) AS role_count
    FROM 
        cast_info ci
    JOIN 
        role_type cr ON ci.role_id = cr.id
    GROUP BY 
        ci.movie_id, cr.role
)
SELECT 
    mh.title,
    mh.production_year,
    mh.linked_title,
    COALESCE(ar.avg_rating, 'N/A') AS average_rating,
    cr.role AS main_role,
    cr.role_count
FROM 
    MovieHierarchy mh
LEFT JOIN 
    AverageRatings ar ON mh.movie_id = ar.movie_id
LEFT JOIN 
    CastPersonRoles cr ON mh.movie_id = cr.movie_id AND cr.role IS NOT NULL
WHERE 
    (mh.production_year BETWEEN 2000 AND 2023) 
    AND (ar.avg_rating IS NULL OR ar.avg_rating > 7.0)
ORDER BY 
    mh.production_year DESC, 
    mh.title,
    main_role DESC;
