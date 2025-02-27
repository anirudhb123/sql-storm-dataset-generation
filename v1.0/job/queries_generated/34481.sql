WITH RECURSIVE movie_hierarchy AS (
    SELECT mt.id AS movie_id, mt.title, mt.production_year, 1 AS level
    FROM aka_title mt
    WHERE mt.production_year >= 2000
    UNION ALL
    SELECT ml.linked_movie_id, at.title, at.production_year, mh.level + 1
    FROM movie_link ml
    JOIN aka_title at ON ml.linked_movie_id = at.id
    JOIN movie_hierarchy mh ON ml.movie_id = mh.movie_id
),
role_stats AS (
    SELECT ci.role_id, COUNT(DISTINCT ci.person_id) AS actor_count, AVG(ci.nr_order) AS avg_order
    FROM cast_info ci
    GROUP BY ci.role_id
),
movie_info_data AS (
    SELECT mi.movie_id, 'All Info' AS info_type, STRING_AGG(mi.info, ', ' ORDER BY mi.info) AS info
    FROM movie_info mi
    GROUP BY mi.movie_id
),
keyword_count AS (
    SELECT mk.movie_id, COUNT(mk.keyword_id) AS keyword_count
    FROM movie_keyword mk
    GROUP BY mk.movie_id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    COALESCE(ki.keyword_count, 0) AS keyword_count,
    COALESCE(rs.actor_count, 0) AS actor_count,
    COALESCE(rs.avg_order, 0) AS avg_order,
    CONCAT('Movie: ', mh.title, ' - Year: ', mh.production_year) AS description,
    CASE 
        WHEN mh.production_year < 2010 THEN 'Classic'
        ELSE 'Modern'
    END AS era,
    SUBSTRING(mh.title FROM 1 FOR 10) || '...' AS short_title,
    info_data.info AS all_info
FROM movie_hierarchy mh
LEFT JOIN keyword_count ki ON mh.movie_id = ki.movie_id
LEFT JOIN role_stats rs ON rs.role_id IN (SELECT role_id FROM cast_info ci WHERE ci.movie_id = mh.movie_id)
LEFT JOIN movie_info_data info_data ON mh.movie_id = info_data.movie_id
WHERE mh.level <= 3
ORDER BY mh.production_year DESC, mh.title
LIMIT 50;
