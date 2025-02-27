WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id, 
        mt.title, 
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id IN (SELECT id FROM kind_type WHERE kind = 'feature')
    
    UNION ALL
    
    SELECT 
        l.linked_movie_id AS movie_id, 
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        movie_link l
    JOIN 
        aka_title m ON l.linked_movie_id = m.id
    JOIN 
        MovieHierarchy mh ON l.movie_id = mh.movie_id
)
SELECT 
    mh.movie_id, 
    mh.title, 
    mh.production_year, 
    CASE 
        WHEN mh.level IS NULL THEN 'No links'
        ELSE 'Level ' || mh.level
    END AS linkage_level,
    COALESCE(SUM(CASE WHEN c.role_id IS NOT NULL THEN 1 END), 0) AS cast_count,
    STRING_AGG(DISTINCT CONCAT(a.name, ' (', a.imdb_index, ')'), ', ') AS cast_details
FROM 
    MovieHierarchy mh
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info c ON cc.subject_id = c.person_id
LEFT JOIN 
    aka_name a ON c.person_id = a.person_id
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, mh.level
HAVING 
    mh.production_year > 2000
ORDER BY 
    mh.production_year DESC, 
    cast_count DESC;