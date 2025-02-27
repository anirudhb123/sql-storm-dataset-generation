WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        t.title,
        t.production_year,
        NULL::integer AS parent_movie_id,
        0 AS level
    FROM title t
    JOIN aka_title a ON t.id = a.movie_id
    JOIN cast_info c ON a.movie_id = c.movie_id
    WHERE t.production_year >= 2000
    UNION ALL
    SELECT 
        m.id AS movie_id,
        t.title,
        t.production_year,
        mh.movie_id AS parent_movie_id,
        mh.level + 1
    FROM title t
    JOIN movie_link ml ON t.id = ml.linked_movie_id
    JOIN MovieHierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    mh.title,
    mh.production_year,
    p.name AS person_name,
    ARRAY_AGG(DISTINCT k.keyword) AS keywords,
    COALESCE(comp.name, 'Independent') AS company_name,
    (SELECT COUNT(*) FROM complete_cast cc WHERE cc.movie_id = mh.movie_id) AS cast_count,
    ROW_NUMBER() OVER (PARTITION BY mh.movie_id ORDER BY mh.level DESC) AS row_num
FROM MovieHierarchy mh
LEFT JOIN movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN keyword k ON mk.keyword_id = k.id
LEFT JOIN movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN company_name comp ON mc.company_id = comp.id
LEFT JOIN cast_info c ON mh.movie_id = c.movie_id
LEFT JOIN aka_name p ON c.person_id = p.person_id
WHERE (mh.level = 0 OR mh.production_year = 2020) 
AND (comp.country_code IS NOT NULL OR comp.name IS NOT NULL)
GROUP BY mh.movie_id, mh.title, mh.production_year, p.name, comp.name
HAVING COUNT(DISTINCT c.person_id) > 2
ORDER BY mh.production_year DESC, mh.title;

