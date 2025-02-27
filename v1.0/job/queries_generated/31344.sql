WITH RECURSIVE MovieHierarchy AS (
    SELECT m.id AS movie_id, 
           m.title, 
           m.production_year, 
           1 AS depth 
    FROM aka_title m 
    WHERE m.production_year >= 2000
    
    UNION ALL
    
    SELECT m.id AS movie_id, 
           m.title, 
           m.production_year, 
           mh.depth + 1 
    FROM aka_title m
    JOIN MovieHierarchy mh ON m.episode_of_id = mh.movie_id
),
CastDetails AS (
    SELECT c.movie_id,
           COUNT(CASE WHEN c.role_id IS NOT NULL THEN 1 END) AS total_roles,
           STRING_AGG(DISTINCT CONCAT(a.name, '(', rt.role, ')'), ', ') AS cast_list
    FROM cast_info c
    LEFT JOIN aka_name a ON c.person_id = a.person_id
    LEFT JOIN role_type rt ON c.role_id = rt.id
    GROUP BY c.movie_id
),
MovieWithInfo AS (
    SELECT m.id AS movie_id, 
           m.title, 
           m.production_year, 
           COALESCE(mi.info, 'No Info') AS movie_info,
           sub.cast_list, 
           sub.total_roles
    FROM aka_title m
    LEFT JOIN movie_info mi ON m.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Synopsis')
    LEFT JOIN CastDetails sub ON m.id = sub.movie_id
)
SELECT mh.movie_id,
       mh.title,
       mh.production_year,
       COALESCE(mwi.movie_info, 'No information available') AS synopsis,
       mwi.cast_list,
       mwi.total_roles,
       CASE 
           WHEN mh.depth > 1 THEN 'Part of a Series'
           ELSE 'Standalone Movie'
       END AS movie_type
FROM MovieHierarchy mh
LEFT JOIN MovieWithInfo mwi ON mh.movie_id = mwi.movie_id
ORDER BY mh.production_year DESC, mh.title;
