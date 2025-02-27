WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS depth,
        COALESCE(mt.kind, 'Unknown') AS kind
    FROM 
        aka_title m
    LEFT JOIN 
        kind_type mt ON m.kind_id = mt.id
    WHERE 
        m.production_year >= 2000 
        AND m.title IS NOT NULL
        
    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        lt.title,
        lt.production_year,
        mh.depth + 1,
        COALESCE(kt.kind, 'Unknown') AS kind
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title lt ON ml.linked_movie_id = lt.id
    LEFT JOIN 
        kind_type kt ON lt.kind_id = kt.id
)
SELECT 
    mh.movie_id, 
    mh.title, 
    mh.production_year, 
    mh.kind,
    COUNT(ci.id) AS total_cast,
    AVG(COALESCE(CASE WHEN r.role IS NOT NULL THEN 1 ELSE 0 END, 0)) AS avg_roles,
    STRING_AGG(DISTINCT an.name, ', ') AS actor_names,
    COUNT(DISTINCT mi.info_type_id) AS info_types_count
FROM 
    MovieHierarchy mh
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.id
LEFT JOIN 
    role_type r ON ci.role_id = r.id
LEFT JOIN 
    aka_name an ON ci.person_id = an.person_id
LEFT JOIN 
    movie_info mi ON mh.movie_id = mi.movie_id
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, mh.kind
HAVING 
    COUNT(ci.id) > 0 AND AVG(COALESCE(CASE WHEN r.role IS NOT NULL THEN 1 ELSE 0 END, 0)) > 0.5
ORDER BY 
    mh.production_year DESC, total_cast DESC;
