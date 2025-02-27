WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        COALESCE(ca.name, 'Unknown') AS actor_name,
        COALESCE(cd.name, 'Unknown') AS director_name,
        COALESCE(co.name, 'Unknown') AS company_name,
        m.production_year,
        1 AS depth
    FROM aka_title m
    LEFT JOIN cast_info ci ON m.id = ci.movie_id
    LEFT JOIN aka_name ca ON ci.person_id = ca.person_id
    LEFT JOIN movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN company_name co ON mc.company_id = co.id
    LEFT JOIN movie_info mi ON m.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Director' LIMIT 1)
    LEFT JOIN aka_name cd ON mi.info = cd.name
    WHERE m.production_year IS NOT NULL

    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        COALESCE(ca.name, 'Unknown') AS actor_name,
        COALESCE(cd.name, 'Unknown') AS director_name,
        COALESCE(co.name, 'Unknown') AS company_name,
        m.production_year,
        mh.depth + 1
    FROM aka_title m
    JOIN movie_hierarchy mh ON m.id = mh.movie_id
    LEFT JOIN cast_info ci ON m.id = ci.movie_id
    LEFT JOIN aka_name ca ON ci.person_id = ca.person_id
    LEFT JOIN movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN company_name co ON mc.company_id = co.id
    LEFT JOIN movie_info mi ON m.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Director' LIMIT 1)
    LEFT JOIN aka_name cd ON mi.info = cd.name
    WHERE m.production_year IS NOT NULL AND mh.depth < 5
)

SELECT 
    mh.movie_title,
    mh.actor_name,
    mh.director_name,
    mh.company_name,
    mh.production_year,
    COUNT(DISTINCT mh.movie_id) OVER (PARTITION BY mh.company_name ORDER BY mh.production_year) AS movies_by_company,
    DENSE_RANK() OVER (ORDER BY mh.production_year DESC) AS rank_by_year,
    CASE 
        WHEN mh.actor_name IS NULL THEN 'No actor available'
        WHEN mh.actor_name LIKE '%Smith%' THEN 'Smith is involved'
        ELSE 'Actor is present'
    END AS actor_status,
    NULLIF(mh.actor_name, 'Unknown') AS actor_checked,
    CASE 
        WHEN mh.production_year >= 2000 THEN 'Modern Era'
        WHEN mh.production_year < 1980 THEN 'Classic Era'
        ELSE 'Unknown Era'
    END AS era_category
FROM movie_hierarchy mh
WHERE mh.depth = 2
ORDER BY mh.production_year DESC, mh.actor_name
FETCH FIRST 50 ROWS ONLY;
