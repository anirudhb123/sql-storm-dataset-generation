WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title AS title,
        m.production_year,
        1 AS level
    FROM title m
    WHERE m.production_year >= 2000

    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title AS title,
        m.production_year,
        mh.level + 1
    FROM title m
    JOIN movie_link ml ON m.id = ml.linked_movie_id
    JOIN movie_hierarchy mh ON mh.movie_id = ml.movie_id
    WHERE mh.level < 3
),

cast_info_with_roles AS (
    SELECT 
        ci.movie_id,
        ci.person_id,
        ci.role_id,
        r.role AS role_name,
        ci.nr_order,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS actor_order
    FROM cast_info ci
    LEFT JOIN role_type r ON ci.role_id = r.id
),

top_movies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COUNT(ci.person_id) AS actor_count
    FROM movie_hierarchy mh
    LEFT JOIN cast_info_with_roles ci ON mh.movie_id = ci.movie_id
    GROUP BY mh.movie_id, mh.title, mh.production_year
    HAVING COUNT(ci.person_id) > 2
)

SELECT 
    tm.title,
    tm.production_year,
    COALESCE(NULLIF(tm.actor_count, 0), 'No Actors') AS actor_count,
    STRING_AGG(DISTINCT ak.name, ', ') AS actor_names,
    COUNT(DISTINCT mk.keyword) AS keyword_count,
    CASE 
        WHEN tm.production_year < 2010 THEN 'Classic'
        WHEN tm.production_year >= 2010 AND tm.production_year < 2015 THEN 'Recent'
        ELSE 'Current'
    END AS era_category
FROM top_movies tm
LEFT JOIN aka_title at ON tm.movie_id = at.movie_id
LEFT JOIN aka_name ak ON ak.person_id IN (SELECT ci.person_id FROM cast_info ci WHERE ci.movie_id = tm.movie_id)
LEFT JOIN movie_keyword mk ON mk.movie_id = tm.movie_id
GROUP BY tm.movie_id, tm.title, tm.production_year, tm.actor_count
ORDER BY tm.production_year DESC, actor_count DESC NULLS LAST;
