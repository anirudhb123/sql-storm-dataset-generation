WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level,
        NULL::integer AS parent_movie_id
    FROM title mt
    WHERE mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        t.title,
        t.production_year,
        mh.level + 1,
        mh.movie_id AS parent_movie_id
    FROM MovieHierarchy mh
    JOIN movie_link ml ON mh.movie_id = ml.movie_id
    JOIN title t ON ml.linked_movie_id = t.id
)
SELECT 
    m.id AS movie_id,
    m.title AS movie_title,
    m.production_year,
    COUNT(DISTINCT c.person_id) AS total_cast_count,
    MAX(CASE WHEN c.role_id IS NOT NULL THEN 1 ELSE 0 END) AS has_roles,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    AVG(mi.production_year) FILTER (WHERE mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'Year')) OVER() AS average_year_of_casted_movies,
    COUNT(DISTINCT cm.company_id) FILTER (WHERE ct.kind = 'Distributor') AS distributors_count
FROM MovieHierarchy m
LEFT JOIN cast_info c ON m.movie_id = c.movie_id
LEFT JOIN movie_keyword mk ON m.movie_id = mk.movie_id
LEFT JOIN keyword k ON mk.keyword_id = k.id
LEFT JOIN movie_companies mc ON m.movie_id = mc.movie_id
LEFT JOIN company_name cn ON mc.company_id = cn.id
LEFT JOIN company_type ct ON mc.company_type_id = ct.id
LEFT JOIN movie_info mi ON m.movie_id = mi.movie_id
GROUP BY m.id, m.title, m.production_year
ORDER BY m.production_year DESC, total_cast_count DESC
LIMIT 50;
