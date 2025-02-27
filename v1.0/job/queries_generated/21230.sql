WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COALESCE(ct.kind, 'Unknown') AS kind,
        COALESCE(cn.name, 'Independent') AS company_name,
        1 AS level
    FROM title t
    LEFT JOIN movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN company_name cn ON mc.company_id = cn.id
    LEFT JOIN company_type ct ON mc.company_type_id = ct.id
    WHERE t.production_year IS NOT NULL

    UNION ALL

    SELECT 
        t.id,
        t.title,
        t.production_year,
        COALESCE(ct.kind, 'Unknown') AS kind,
        COALESCE(cn.name, 'Independent') AS company_name,
        mh.level + 1
    FROM title t
    INNER JOIN movie_link ml ON t.id = ml.linked_movie_id
    INNER JOIN movie_hierarchy mh ON ml.movie_id = mh.title_id
)

SELECT 
    mh.title,
    mh.production_year,
    mh.kind,
    mh.company_name,
    COUNT(DISTINCT p.id) AS total_actors,
    SUM(CASE WHEN c.note IS NOT NULL THEN 1 ELSE 0 END) AS total_cast_notes,
    STRING_AGG(DISTINCT ak.name, ', ') AS aka_names,
    ROW_NUMBER() OVER (PARTITION BY mh.kind ORDER BY mh.production_year DESC) AS rank_within_kind
FROM movie_hierarchy mh
LEFT JOIN cast_info c ON mh.title_id = c.movie_id
LEFT JOIN aka_name ak ON ak.person_id = c.person_id
LEFT JOIN person_info pi ON pi.person_id = ak.person_id AND pi.info_type_id IN (SELECT id FROM info_type WHERE info = 'Height')
LEFT JOIN name n ON n.id = c.person_role_id
WHERE mh.production_year > 2000
AND (mh.kind = 'feature' OR mh.kind IS NULL) 
AND (mh.company_name IS NOT NULL OR mh.company_name != 'Independent')
GROUP BY 
    mh.title, 
    mh.production_year, 
    mh.kind, 
    mh.company_name
HAVING 
    COUNT(DISTINCT p.id) > 5 
    AND SUM(CASE WHEN c.note IS NOT NULL THEN 1 ELSE 0 END) > 0
ORDER BY 
    mh.production_year DESC, 
    total_actors DESC;

