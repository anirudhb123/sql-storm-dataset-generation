WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        NULL::integer AS parent_movie_id,
        mt.production_year,
        1 AS level
    FROM aka_title mt
    WHERE mt.production_year >= 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        mh.movie_id AS parent_movie_id,
        at.production_year,
        mh.level + 1
    FROM MovieHierarchy mh
    JOIN movie_link ml ON mh.movie_id = ml.movie_id
    JOIN aka_title at ON ml.linked_movie_id = at.id
)

SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    string_agg(DISTINCT a.name, ', ') FILTER (WHERE a.name IS NOT NULL) AS actors,
    COUNT(DISTINCT mk.keyword) AS keyword_count,
    SUM(CASE WHEN pi.info IS NOT NULL THEN 1 ELSE 0 END) AS person_info_count,
    COUNT(DISTINCT mc.company_id) FILTER (WHERE ct.kind IS NOT NULL) AS production_companies,
    ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY mh.title) AS rank_per_year
FROM MovieHierarchy mh
LEFT OUTER JOIN cast_info ci ON mh.movie_id = ci.movie_id
LEFT JOIN aka_name a ON ci.person_id = a.person_id
LEFT JOIN movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN person_info pi ON ci.person_id = pi.person_id
LEFT JOIN movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN company_type ct ON mc.company_type_id = ct.id
WHERE mh.level <= 2  -- Limit to a hierarchy of two levels
GROUP BY mh.movie_id, mh.title, mh.production_year
HAVING COUNT(DISTINCT a.id) >= 1  -- Only include movies with at least one actor
ORDER BY mh.production_year DESC, mh.title;

