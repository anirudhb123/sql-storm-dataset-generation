WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        0 AS depth,
        CAST(m.title AS VARCHAR(255)) AS full_path
    FROM 
        aka_title m
    WHERE 
        m.production_year BETWEEN 2000 AND 2023

    UNION ALL

    SELECT 
        m2.id,
        m2.title,
        m2.production_year,
        mh.depth + 1,
        CAST(mh.full_path || ' -> ' || m2.title AS VARCHAR(255))
    FROM 
        movie_link ml
    JOIN 
        aka_title m2 ON ml.linked_movie_id = m2.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    WHERE 
        mh.depth < 3  -- Limit levels to 3
)

SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    mh.depth,
    mh.full_path,
    ak.name AS actor_name,
    COALESCE(ki.keyword, 'No Keyword') AS keyword,
    COUNT(DISTINCT ci.role_id) AS role_count,
    AVG(CASE WHEN ci.nr_order IS NOT NULL THEN ci.nr_order ELSE 0 END) AS avg_order,
    STRING_AGG(DISTINCT ci.note, ', ') FILTER (WHERE ci.note IS NOT NULL) AS notes,
    CASE 
        WHEN COUNT(DISTINCT ci.role_id) > 2 THEN 'Ensemble Cast'
        ELSE 'Solo Performer'
    END AS cast_size_category
FROM 
    movie_hierarchy mh
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.id = ci.movie_id
LEFT JOIN 
    aka_name ak ON ci.person_id = ak.person_id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    keyword ki ON mk.keyword_id = ki.id
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, mh.depth, mh.full_path, ak.name, ki.keyword
HAVING 
    (avg_order > 0 OR COUNT(ak.name) = 0) AND
    mh.production_year IS NOT NULL
ORDER BY 
    mh.production_year DESC, mh.depth ASC, mh.title;

