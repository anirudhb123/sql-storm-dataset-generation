WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        1 AS level,
        NULL::integer AS parent_id
    FROM 
        title m
    WHERE 
        m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL

    SELECT 
        mv.linked_movie_id,
        t.title,
        mh.level + 1 AS level,
        mv.movie_id AS parent_id
    FROM 
        movie_link mv
    JOIN 
        title t ON mv.linked_movie_id = t.id
    JOIN 
        MovieHierarchy mh ON mv.movie_id = mh.movie_id
)
SELECT 
    t.title AS movie_title,
    coalesce(cn.name, 'Unknown') AS company_name,
    STRING_AGG(DISTINCT an.name, ', ') AS actor_names,
    mh.level AS hierarchy_level,
    COUNT(DISTINCT mk.keyword) AS num_keywords,
    AVG(m.production_year) FILTER (WHERE m.production_year IS NOT NULL) AS avg_production_year
FROM 
    MovieHierarchy mh
JOIN 
    movie_companies mc ON mh.movie_id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.id
JOIN 
    aka_name an ON ci.person_id = an.person_id
JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
JOIN 
    title t ON mh.movie_id = t.id
LEFT JOIN 
    movie_info mi ON mh.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'tagline')
WHERE 
    mh.level <= 2 
    AND (ci.note IS NULL OR ci.note != 'Cameo')
GROUP BY 
    mh.movie_id, cn.name, mh.level
ORDER BY 
    hierarchy_level, num_keywords DESC, movie_title;
