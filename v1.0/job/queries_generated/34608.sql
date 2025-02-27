WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        NULL::integer AS parent_id,
        0 AS level
    FROM 
        aka_title m
    WHERE 
        m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    UNION ALL
    SELECT 
        m.id AS movie_id,
        m.title,
        mh.movie_id AS parent_id,
        mh.level + 1
    FROM 
        aka_title m
    JOIN 
        movie_link ml ON m.id = ml.linked_movie_id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.parent_id,
    mh.level,
    COALESCE(AKA.name, 'Unknown') AS aka_name,
    COUNT(DISTINCT ci.person_id) AS actor_count,
    STRING_AGG(DISTINCT COALESCE(cn.name, 'N/A'), ', ') AS character_names,
    SUM(CASE WHEN mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Budget') THEN mi.info::numeric ELSE 0 END) AS total_budget
FROM 
    MovieHierarchy mh
LEFT JOIN 
    aka_name AKA ON mh.movie_id = AKA.movie_id
LEFT JOIN 
    cast_info ci ON mh.movie_id = ci.movie_id
LEFT JOIN 
    char_name cn ON ci.role_id = cn.id
LEFT JOIN 
    movie_info mi ON mh.movie_id = mi.movie_id
GROUP BY 
    mh.movie_id, mh.title, mh.parent_id, mh.level, AKA.name
HAVING 
    COUNT(DISTINCT ci.person_id) > 3
ORDER BY 
    mh.level, total_budget DESC NULLS LAST;
