WITH RECURSIVE movie_hierarchy AS (
    SELECT m.id AS movie_id, m.title, m.production_year, 
           array[m.id] AS path
    FROM aka_title m
    WHERE m.episode_of_id IS NULL
    
    UNION ALL
    
    SELECT m.id, m.title, m.production_year, 
           mh.path || m.id
    FROM aka_title m
    JOIN movie_hierarchy mh ON m.episode_of_id = mh.movie_id
),
cast_with_roles AS (
    SELECT c.movie_id, 
           ARRAY_AGG(DISTINCT CONCAT(a.name, ' as ', r.role)) AS cast_list
    FROM cast_info c
    JOIN aka_name a ON c.person_id = a.person_id
    JOIN role_type r ON c.role_id = r.id
    GROUP BY c.movie_id
),
company_details AS (
    SELECT m.movie_id, 
           STRING_AGG(DISTINCT cn.name, ', ') AS companies,
           STRING_AGG(DISTINCT ct.kind, ', ') AS company_types
    FROM movie_companies m
    JOIN company_name cn ON m.company_id = cn.id
    JOIN company_type ct ON m.company_type_id = ct.id
    GROUP BY m.movie_id
),
movie_info_details AS (
    SELECT movie_id, 
           jsonb_build_object('info1', MAX(CASE WHEN it.info = 'summary' THEN mi.info END),
                              'info2', MAX(CASE WHEN it.info = 'rating' THEN mi.info END),
                              'info3', MAX(CASE WHEN it.info = 'duration' THEN mi.info END)) AS movie_info
    FROM movie_info mi
    JOIN info_type it ON mi.info_type_id = it.id
    GROUP BY movie_id
)
SELECT mh.movie_id, mh.title, mh.production_year, 
       COALESCE(cl.cast_list, '{}') AS cast, 
       COALESCE(cd.companies, 'Unknown') AS companies,
       COALESCE(cd.company_types, 'Unknown') AS company_types,
       mi.movie_info
FROM movie_hierarchy mh
LEFT JOIN cast_with_roles cl ON mh.movie_id = cl.movie_id
LEFT JOIN company_details cd ON mh.movie_id = cd.movie_id
LEFT JOIN movie_info_details mi ON mh.movie_id = mi.movie_id
WHERE mh.production_year >= 2000
  AND (mi.movie_info->>'info1' IS NOT NULL)
ORDER BY mh.production_year DESC, mh.title;
