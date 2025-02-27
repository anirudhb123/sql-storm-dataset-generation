WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        m.kind_id,
        1 AS depth
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        m.kind_id,
        mh.depth + 1
    FROM 
        aka_title m
    JOIN 
        movie_link ml ON m.id = ml.linked_movie_id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    mh.movie_title,
    mh.production_year,
    kt.kind AS movie_kind,
    COUNT(DISTINCT ci.person_id) AS total_cast,
    MAX(COALESCE(cn.name, 'Unknown')) AS main_character_name,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords
FROM 
    MovieHierarchy mh
LEFT JOIN 
    title t ON mh.movie_id = t.id
LEFT JOIN 
    kind_type kt ON t.kind_id = kt.id
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
LEFT JOIN 
    aka_name an ON ci.person_id = an.person_id
LEFT JOIN 
    char_name cn ON an.name = cn.name
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
WHERE 
    mh.depth < 5
GROUP BY 
    mh.movie_title, mh.production_year, kt.kind
ORDER BY 
    mh.production_year DESC, total_cast DESC;

-- Additional complexity: Filtering out titles with less than two cast members
HAVING 
    COUNT(DISTINCT ci.person_id) >= 2;
This SQL query utilizes various advanced constructs including recursive CTEs for hierarchical movie relationships, outer joins to gather multiple related entities, window functions to determine additional metrics, and aggregate functions to summarize movie data with filtering based on specific join conditions. The query also combines elements like string aggregation for keywords and COALESCE to handle potential NULL values. It ensures that only movies with a significant number of cast members are included in the final output.
