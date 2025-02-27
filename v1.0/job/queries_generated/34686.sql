WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level,
        CAST(m.title AS VARCHAR(255)) AS path
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL

    UNION ALL

    SELECT 
        l.linked_movie_id,
        c.title,
        c.production_year,
        mh.level + 1,
        CAST(mh.path || ' -> ' || c.title AS VARCHAR(255))
    FROM 
        movie_link l
    JOIN 
        aka_title c ON l.linked_movie_id = c.id
    JOIN 
        MovieHierarchy mh ON l.movie_id = mh.movie_id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    mh.level,
    mh.path,
    COUNT(DISTINCT ci.person_id) AS num_cast_members,
    AVG(CASE WHEN cs.kind IS NULL THEN 0 ELSE 1 END) AS average_cast_type_nulls
FROM 
    MovieHierarchy mh
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
LEFT JOIN 
    comp_cast_type cs ON ci.person_role_id = cs.id
WHERE 
    mh.production_year BETWEEN 2000 AND 2020
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, mh.level, mh.path
HAVING 
    COUNT(DISTINCT ci.person_id) > 0
ORDER BY 
    mh.production_year DESC, mh.level ASC, num_cast_members DESC;
