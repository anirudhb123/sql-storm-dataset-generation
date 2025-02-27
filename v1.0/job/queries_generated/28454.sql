WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level,
        CAST(m.title AS TEXT) AS path
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000

    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1,
        CAST(mh.path || ' -> ' || m.title AS TEXT) AS path
    FROM 
        movie_link ml
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
    WHERE 
        mh.level < 3  -- Limit hierarchy depth
)

SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    mh.level,
    mh.path,
    ARRAY_AGG(DISTINCT ak.name) AS actor_names,
    COUNT(DISTINCT kc.keyword) AS total_keywords,
    COUNT(DISTINCT cc.kind) AS company_types_involved
FROM 
    MovieHierarchy mh
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
LEFT JOIN 
    aka_name ak ON ci.person_id = ak.person_id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    keyword kc ON mk.keyword_id = kc.id
LEFT JOIN 
    movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN 
    company_type ct ON mc.company_type_id = ct.id
WHERE 
    mh.title IS NOT NULL
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, mh.level, mh.path
ORDER BY 
    mh.production_year DESC, mh.level DESC;
