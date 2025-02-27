WITH RECURSIVE movie_hierarchy AS (
    SELECT m.id AS movie_id,
           0 AS level,
           m.title,
           m.production_year,
           NULL AS parent_id
    FROM aka_title m
    WHERE m.production_year IS NOT NULL 
    UNION ALL
    SELECT m.id AS movie_id,
           mh.level + 1,
           m.title,
           m.production_year,
           mh.movie_id AS parent_id
    FROM aka_title m
    JOIN movie_link ml ON ml.movie_id = mh.movie_id
    JOIN movie_info mi ON mi.movie_id = ml.linked_movie_id
    JOIN movie_hierarchy mh ON mh.movie_id = mi.movie_id
    WHERE mh.level < 5
)

SELECT 
    COALESCE(a.name, 'Unknown') AS actor_name,
    AVG(CASE 
            WHEN c.nr_order IS NOT NULL THEN c.nr_order + 1
            ELSE 0 
        END) AS avg_cast_order,
    COUNT(DISTINCT m.id) FILTER (WHERE m.production_year IS NOT NULL) AS distinct_movies,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    COUNT(DISTINCT mh.movie_id) AS related_movies,
    SUM(m.production_year) OVER (PARTITION BY a.id ORDER BY m.production_year DESC) AS cumulative_years,
    MAX(k.keyword) AS latest_keyword,
    MIN(CASE WHEN cm.kind = 'Production Company' THEN cm.name ELSE NULL END) AS first_production_company,
    COUNT(DISTINCT CASE WHEN r.role IS NOT NULL THEN r.role END) AS role_count
FROM aka_name a
LEFT JOIN cast_info c ON a.person_id = c.person_id
LEFT JOIN aka_title m ON c.movie_id = m.id
LEFT JOIN movie_keyword mk ON mk.movie_id = m.id
LEFT JOIN keyword k ON mk.keyword_id = k.id
LEFT JOIN movie_companies mc ON m.id = mc.movie_id
LEFT JOIN company_name cm ON mc.company_id = cm.id
LEFT JOIN role_type r ON c.role_id = r.id
LEFT JOIN movie_hierarchy mh ON mh.movie_id = m.id
WHERE a.name IS NOT NULL
GROUP BY a.id
HAVING COUNT(DISTINCT m.id) > 1
   OR AVG(c.nr_order) IS NOT NULL
ORDER BY avg_cast_order DESC, related_movies DESC;

This SQL query involves a recursive CTE to explore movie relationships, complex aggregations using window functions, and incorporates several outer joins, filters, and groupings. It also showcases peculiar corner cases by utilizing `COALESCE`, conditional aggregations with `CASE`, and filters in the `HAVING` clause, ensuring records meet certain logical conditions. Finally, it employs `STRING_AGG` to concatenate unique keywords into a comma-separated list.
