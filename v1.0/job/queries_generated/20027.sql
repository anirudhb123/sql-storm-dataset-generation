WITH RECURSIVE movie_hierarchy AS (
    SELECT mt.id AS movie_id, mt.title, mt.production_year, 
           COALESCE(SECOND_LEVEL.parent_title, 'N/A') AS parent_title,
           1 AS level
    FROM aka_title mt
    LEFT JOIN (
        SELECT m.id AS child_id, mt.title AS parent_title
        FROM movie_link ml
        JOIN aka_title m ON ml.linked_movie_id = m.id
        JOIN aka_title mt ON ml.movie_id = mt.id
        WHERE ml.link_type_id = 1
    ) AS SECOND_LEVEL ON mt.id = SECOND_LEVEL.child_id 
    WHERE mt.kind_id = 1  -- only considering 'movie'

    UNION ALL

    SELECT mt.id AS movie_id, mt.title, mt.production_year,
           COALESCE(mh.parent_title, 'N/A') AS parent_title,
           mh.level + 1
    FROM aka_title mt
    JOIN movie_hierarchy mh ON mt.id = mh.movie_id
    WHERE mh.level < 3  -- limit to 3 levels deep for performance
),
actor_movie_roles AS (
    SELECT ca.movie_id, ca.person_role_id, COUNT(*) AS role_count
    FROM cast_info ca
    JOIN aka_name a ON ca.person_id = a.person_id
    WHERE a.name IS NOT NULL
    GROUP BY ca.movie_id, ca.person_role_id
),
keyword_aggregation AS (
    SELECT mk.movie_id, STRING_AGG(k.keyword, ', ') AS keywords 
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
),
movie_rating_info AS (
    SELECT m.id AS movie_id, AVG(pi.info::numeric) AS average_rating
    FROM movie_info m
    JOIN person_info pi ON m.movie_id = pi.person_id
    WHERE pi.info_type_id = (SELECT id FROM info_type WHERE info = 'Rating')
    GROUP BY m.id
)
SELECT mh.movie_id, mh.title, mh.production_year, 
       COALESCE(k.keywords, 'No Keywords') AS keywords,
       COALESCE(air.role_count, 0) AS total_roles,
       COALESCE(mri.average_rating, 'No ratings') AS average_rating,
       CASE 
           WHEN COALESCE(mri.average_rating, 0) >= 8.0 THEN 'Highly Rated'
           WHEN COALESCE(mri.average_rating, 0) BETWEEN 5.0 AND 7.9 THEN 'Moderately Rated'
           ELSE 'Low Rated' 
       END AS rating_category,
       CASE 
           WHEN mh.level IS NULL THEN 'No Parent Movie'
           ELSE CONCAT('Parent: ', mh.parent_title, ' (Level: ', mh.level, ')')
       END AS movie_hierarchy_info
FROM movie_hierarchy mh
LEFT JOIN keyword_aggregation k ON mh.movie_id = k.movie_id
LEFT JOIN actor_movie_roles air ON mh.movie_id = air.movie_id
LEFT JOIN movie_rating_info mri ON mh.movie_id = mri.movie_id
ORDER BY mh.production_year DESC, mh.title;
