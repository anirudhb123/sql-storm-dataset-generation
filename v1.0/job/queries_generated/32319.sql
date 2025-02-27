WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        0 AS level,
        CAST(t.title AS VARCHAR(255)) AS path
    FROM 
        aka_title t
    WHERE 
        t.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        m.linked_movie_id AS movie_id,
        l.title,
        l.production_year,
        mh.level + 1,
        CAST(mh.path || ' -> ' || l.title AS VARCHAR(255)) AS path
    FROM 
        movie_link m
    JOIN 
        title l ON m.linked_movie_id = l.id
    JOIN 
        MovieHierarchy mh ON m.movie_id = mh.movie_id
)

SELECT 
    mh.path,
    mh.production_year,
    COUNT(DISTINCT ci.person_id) AS total_cast,
    STRING_AGG(DISTINCT ak.name, ', ') AS cast_names,
    AVG(COALESCE(mk.count_keyword, 0)) AS avg_keywords_per_movie
FROM 
    MovieHierarchy mh
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON ci.movie_id = mh.movie_id
LEFT JOIN 
    aka_name ak ON ak.person_id = ci.person_id
LEFT JOIN 
    (SELECT 
         movie_id, 
         COUNT(DISTINCT keyword_id) AS count_keyword 
     FROM 
         movie_keyword 
     GROUP BY 
         movie_id) mk ON mk.movie_id = mh.movie_id
WHERE 
    mh.level < 3
GROUP BY 
    mh.path, mh.production_year
ORDER BY 
    mh.production_year DESC, total_cast DESC
LIMIT 50;
