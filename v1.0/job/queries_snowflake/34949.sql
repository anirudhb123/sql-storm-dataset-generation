
WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        0 AS level,
        CAST(mt.title AS VARCHAR) AS path
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2020  
    UNION ALL
    SELECT 
        ml.linked_movie_id,
        m.title,
        level + 1,
        mh.path || ' -> ' || m.title
    FROM 
        movie_link ml
    JOIN 
        title m ON ml.linked_movie_id = m.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.level,
    mh.path,
    COUNT(DISTINCT ci.person_id) AS cast_count,
    AVG(CASE WHEN ci.note IS NULL THEN 0 ELSE 1 END) AS has_note,
    LISTAGG(DISTINCT a.name, ', ') WITHIN GROUP (ORDER BY a.name) AS actors,
    ARRAY_AGG(DISTINCT k.keyword) AS keywords,
    COALESCE(cn.name, 'Unknown Company') AS production_company
FROM 
    MovieHierarchy mh
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
LEFT JOIN 
    aka_name a ON ci.person_id = a.person_id
LEFT JOIN 
    movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
GROUP BY 
    mh.movie_id, mh.title, mh.level, mh.path, cn.name
HAVING 
    COUNT(DISTINCT ci.person_id) > 5  
ORDER BY 
    mh.level DESC, cast_count DESC;
