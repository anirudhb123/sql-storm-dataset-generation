WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        NULL::INTEGER AS parent_movie_id
    FROM 
        aka_title m
    WHERE 
        m.kind_id = 1 -- assuming '1' for feature films
    
    UNION ALL
    
    SELECT 
        l.linked_movie_id AS movie_id,
        m.title,
        m.production_year,
        l.movie_id AS parent_movie_id
    FROM 
        movie_link l
    JOIN 
        aka_title m ON l.linked_movie_id = m.id
    WHERE 
        l.link_type_id = 1 -- assuming '1' for 'related'
)
SELECT 
    mh.title AS movie_title,
    mh.production_year,
    COUNT(DISTINCT ci.person_id) AS actor_count,
    STRING_AGG(DISTINCT ak.name, ', ') AS actors,
    MAX(CASE 
        WHEN pi.info_type_id = 1 THEN pi.info 
        ELSE NULL 
    END) AS director_name,
    COALESCE(SUM(mo.info_text_length), 0) AS total_info_length,
    MAX(CASE 
        WHEN kw.keyword IS NOT NULL THEN kw.keyword 
        ELSE 'No Keywords' 
    END) AS movie_keywords 
FROM 
    MovieHierarchy mh
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON ci.movie_id = cc.movie_id
LEFT JOIN 
    aka_name ak ON ak.person_id = ci.person_id
LEFT JOIN 
    movie_info mi ON mh.movie_id = mi.movie_id
LEFT JOIN 
    movie_info_idx mo ON mi.movie_id = mo.movie_id
LEFT JOIN 
    person_info pi ON ci.person_id = pi.person_id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
GROUP BY 
    mh.movie_id
ORDER BY 
    mh.production_year DESC, 
    actor_count DESC
LIMIT 10;
