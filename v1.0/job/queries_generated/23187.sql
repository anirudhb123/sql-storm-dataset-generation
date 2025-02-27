WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        1 AS depth,
        ARRAY[m.title] AS movie_path
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL
        
    UNION ALL
    
    SELECT 
        m.id AS movie_id,
        m.title,
        mh.depth + 1,
        mh.movie_path || m.title
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
    mh.depth,
    COUNT(DISTINCT ci.person_id) AS num_cast_members,
    STRING_AGG(DISTINCT p.name, ', ') AS cast_names,
    COALESCE(MIN(mk.keyword), 'No Keywords') AS first_keyword,
    STRING_AGG(DISTINCT k.keyword, '; ') FILTER (WHERE k.keyword IS NOT NULL) AS all_keywords,
    CASE 
        WHEN count(mk.keyword) > 0 THEN 'Keywords Found' 
        ELSE 'No Keywords Found' 
    END AS keyword_status,
    AVG(CASE WHEN ci.nr_order IS NOT NULL THEN ci.nr_order ELSE NULL END) AS avg_order
FROM 
    MovieHierarchy mh
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
LEFT JOIN 
    aka_name p ON ci.person_id = p.person_id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    mh.depth <= 3
GROUP BY 
    mh.movie_id, mh.title, mh.depth
ORDER BY 
    mh.depth DESC, num_cast_members DESC, mh.title
LIMIT 50;
