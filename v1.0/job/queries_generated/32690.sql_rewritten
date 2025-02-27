WITH RECURSIVE MovieHierarchy AS (
    
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        1 AS level
    FROM 
        title t
    WHERE 
        t.episode_of_id IS NULL

    UNION ALL

    
    SELECT 
        e.id AS movie_id,
        e.title,
        e.production_year,
        mh.level + 1
    FROM 
        title e
    INNER JOIN 
        MovieHierarchy mh ON e.episode_of_id = mh.movie_id
)

SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    COALESCE(cmp.kind, 'Unknown') AS company_type,
    COUNT(DISTINCT ci.person_id) AS total_cast_members,
    STRING_AGG(DISTINCT ak.name, ', ') AS cast_names,
    AVG(CASE 
            WHEN r.role IS NULL THEN 0 
            ELSE 1 
        END) AS average_role_assigned,
    SUM(CASE 
            WHEN ci.note IS NOT NULL THEN 1 
            ELSE 0 
        END) AS notes_count,
    (SELECT COUNT(*) 
     FROM movie_info mi 
     WHERE mi.movie_id = mh.movie_id AND mi.info_type_id IN (1, 2)) AS info_count
FROM 
    MovieHierarchy mh
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
LEFT JOIN 
    aka_name ak ON ak.person_id = ci.person_id
LEFT JOIN 
    movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN 
    company_type cmp ON mc.company_type_id = cmp.id
LEFT JOIN 
    role_type r ON ci.role_id = r.id
WHERE 
    mh.production_year BETWEEN 2000 AND 2020
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, cmp.kind
ORDER BY 
    mh.production_year DESC, mh.title ASC;