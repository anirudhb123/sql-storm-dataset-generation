WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        COALESCE(m.production_year, 0) AS production_year,
        COALESCE(mk.keyword, 'Unspecified') AS keyword,
        1 AS level
    FROM aka_title m
    LEFT JOIN movie_keyword mk ON m.id = mk.movie_id
    WHERE m.production_year IS NOT NULL
    
    UNION ALL
    
    SELECT 
        m.id AS movie_id,
        m.title,
        COALESCE(m.production_year, 0) AS production_year,
        COALESCE(mk.keyword, 'Unspecified') AS keyword,
        mh.level + 1
    FROM aka_title m
    JOIN movie_link ml ON ml.movie_id = m.id
    JOIN movie_hierarchy mh ON mh.movie_id = ml.linked_movie_id
    WHERE m.production_year IS NULL
)

SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    mh.keyword,
    COUNT(DISTINCT ci.id) AS cast_count,
    SUM(CASE WHEN ci.note IS NULL THEN 1 ELSE 0 END) AS null_notes_count,
    STRING_AGG(DISTINCT a.name, ', ') AS actors,
    ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY mh.title) AS title_rank
FROM movie_hierarchy mh
LEFT JOIN cast_info ci ON ci.movie_id = mh.movie_id
LEFT JOIN aka_name a ON a.person_id = ci.person_id
WHERE mh.production_year BETWEEN 1980 AND 2020 
GROUP BY mh.movie_id, mh.title, mh.production_year, mh.keyword
HAVING COUNT(DISTINCT ci.person_role_id) > 1
   AND STRING_AGG(DISTINCT mk.keyword, ', ') LIKE '%Drama%'
   AND (SELECT COUNT(*) FROM movie_info mi WHERE mi.movie_id = mh.movie_id 
        AND mi.info_type_id IN (SELECT id FROM info_type WHERE info ILIKE '%Awards%')) > 0
ORDER BY mh.production_year DESC, mh.title;

SELECT DISTINCT
    COALESCE(NULLIF(cn.name, ''), '<Unknown Company>') AS company_name,
    CASE 
        WHEN ct.kind IS NULL THEN 'N/A' 
        ELSE ct.kind 
    END AS company_type,
    COUNT(DISTINCT mc.movie_id) AS movies_produced
FROM movie_companies mc
LEFT JOIN company_name cn ON mc.company_id = cn.id
LEFT JOIN company_type ct ON mc.company_type_id = ct.id
WHERE mc.note IS NULL OR mc.note NOT LIKE '%archive%'
GROUP BY cn.name, ct.kind
HAVING COUNT(DISTINCT mc.movie_id) > 3
ORDER BY movies_produced DESC NULLS LAST;

SELECT 
    p.name AS person_name,
    COUNT(DISTINCT c.movie_id) AS movies_appeared_in,
    SUM(CASE WHEN c.note IS NOT NULL THEN 1 ELSE 0 END) AS credited_roles,
    AVG(COALESCE(MARK AS float, 0)) AS average_role_importance
FROM aka_name p
JOIN cast_info c ON p.person_id = c.person_id
WHERE p.md5sum IS NOT NULL
GROUP BY p.name
HAVING SUM(CASE WHEN c.role_id IS NULL THEN 1 ELSE 0 END) > 5
ORDER BY movies_appeared_in DESC, credited_roles ASC;
