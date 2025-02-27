WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id, 
        mt.title, 
        1 AS level,
        mt.production_year,
        0 AS is_ancestor,
        NULL::text AS ancestor_title,
        mt.imdb_index,
        COALESCE(mk.keyword, 'No Keywords') AS keyword
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    WHERE 
        mt.production_year BETWEEN 1990 AND 2000
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        lt.title,
        mh.level + 1,
        lt.production_year,
        1 AS is_ancestor,
        mh.title AS ancestor_title,
        lt.imdb_index,
        COALESCE(mk.keyword, 'No Keywords') AS keyword
    FROM 
        movie_link ml
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title lt ON ml.linked_movie_id = lt.id
    LEFT JOIN 
        movie_keyword mk ON lt.id = mk.movie_id
)

SELECT 
    mh.movie_id,
    mh.title,
    mh.level,
    mh.production_year,
    mh.ancestor_title,
    mh.imdb_index,
    mh.keyword,
    (SELECT COUNT(*) 
     FROM movie_info mi 
     WHERE mi.movie_id = mh.movie_id AND mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'Trivia')
    ) AS trivia_count,
    COUNT(DISTINCT c.person_id) FILTER (WHERE c.role_id IS NOT NULL) AS distinct_roles,
    CASE 
        WHEN mh.level > 1 THEN 'Descendant'
        ELSE 'Root'
    END AS relationship
FROM 
    MovieHierarchy mh
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info c ON cc.subject_id = c.id
GROUP BY 
    mh.movie_id, mh.title, mh.level, mh.production_year, mh.ancestor_title, mh.imdb_index, mh.keyword
HAVING 
    COUNT(DISTINCT mk.keyword) > 2 
ORDER BY 
    mh.production_year DESC, mh.level ASC
LIMIT 50;

-- Check performance benchmarks based on various joins and filtering criteria.

