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
        m.production_year >= 2000

    UNION ALL

    SELECT 
        lm.linked_movie_id AS movie_id,
        lt.title,
        lt.production_year,
        mh.level + 1,
        CAST(CONCAT(mh.path, ' -> ', lt.title) AS VARCHAR(255))
    FROM 
        movie_link lm
    JOIN 
        MovieHierarchy mh ON lm.movie_id = mh.movie_id
    JOIN 
        aka_title lt ON lm.linked_movie_id = lt.id
)

SELECT 
    mh.path,
    mh.production_year,
    COUNT(c.person_id) AS cast_count,
    COUNT(DISTINCT mc.company_id) AS production_companies,
    CASE 
        WHEN mh.production_year < 2010 THEN 'Before 2010'
        ELSE 'After 2010'
    END AS production_period
FROM 
    MovieHierarchy mh
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info c ON cc.subject_id = c.person_id
LEFT JOIN 
    movie_companies mc ON mh.movie_id = mc.movie_id
WHERE 
    mh.level <= 3
GROUP BY 
    mh.path, mh.production_year
HAVING 
    COUNT(c.person_id) > 5 OR COUNT(DISTINCT mc.company_id) > 3
ORDER BY 
    mh.production_year DESC, cast_count DESC
OFFSET 5 LIMIT 10;
