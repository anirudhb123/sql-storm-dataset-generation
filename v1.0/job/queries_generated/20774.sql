WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id, 
        t.title AS movie_title, 
        t.production_year, 
        1 AS level
    FROM 
        aka_title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    WHERE 
        t.production_year IS NOT NULL AND 
        t.title IS NOT NULL

    UNION ALL

    SELECT 
        mh.movie_id, 
        CONCAT(mh.movie_title, ' (Part of Series)') AS movie_title, 
        mh.production_year, 
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        aka_title t ON mh.movie_id = t.episode_of_id
)

SELECT 
    ak.name,
    mt.movie_title,
    mt.production_year,
    COALESCE(STRING_AGG(kw.keyword, ', '), 'No keywords') AS keywords,
    COUNT(DISTINCT cc.person_id) AS cast_count,
    SUM(CASE WHEN cc.note LIKE '%lead%' THEN 1 ELSE 0 END) AS lead_roles,
    COUNT(DISTINCT pi.info_type_id) AS info_type_count,
    MAX(CASE WHEN pi.info IS NOT NULL THEN pi.info END) AS last_info 
FROM 
    aka_name ak
JOIN 
    cast_info cc ON ak.person_id = cc.person_id
JOIN 
    MovieHierarchy mt ON cc.movie_id = mt.movie_id
LEFT JOIN 
    movie_keyword mk ON mt.movie_id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
LEFT JOIN 
    person_info pi ON cc.person_id = pi.person_id
WHERE 
    ak.surname_pcode IS NOT NULL AND 
    ak.name IS NOT NULL AND 
    (mt.production_year BETWEEN 2000 AND 2020 OR mt.production_year IS NULL)
GROUP BY 
    ak.name, mt.movie_title, mt.production_year
HAVING 
    CAST(COUNT(DISTINCT cc.person_id) AS INT) > (SELECT AVG(cast_count) FROM (
        SELECT COUNT(DISTINCT person_id) AS cast_count
        FROM cast_info
        GROUP BY movie_id
    ) AS avg_cast)
ORDER BY 
    mt.production_year DESC, 
    ak.name ASC;
