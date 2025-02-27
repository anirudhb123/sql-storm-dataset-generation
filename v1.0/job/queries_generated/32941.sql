WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM aka_title m
    WHERE m.production_year IS NOT NULL
    UNION ALL
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM aka_title m
    JOIN movie_link ml ON m.id = ml.linked_movie_id
    JOIN movie_hierarchy mh ON ml.movie_id = mh.movie_id
),
cast_details AS (
    SELECT 
        ci.movie_id,
        a.name AS actor_name,
        r.role AS role,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS actor_order
    FROM cast_info ci
    JOIN aka_name a ON ci.person_id = a.person_id
    JOIN role_type r ON ci.role_id = r.id
),
movie_details AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(DISTINCT kw.keyword) AS keyword_count,
        COALESCE(ARRAY_AGG(DISTINCT c.name ORDER BY c.name), '{}') AS companies,
        COUNT(DISTINCT ci.person_id) AS total_actors
    FROM movie_companies mc
    JOIN company_name c ON mc.company_id = c.id
    JOIN aka_title m ON mc.movie_id = m.id
    LEFT JOIN movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN keyword kw ON mk.keyword_id = kw.id
    LEFT JOIN cast_info ci ON m.id = ci.movie_id
    GROUP BY m.id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    md.keyword_count,
    md.companies,
    md.total_actors,
    ARRAY_AGG(DISTINCT cd.actor_name || ' (' || cd.role || ')' ORDER BY cd.actor_order) AS actor_roles,
    CASE 
        WHEN md.total_actors > 10 THEN 'High'
        WHEN md.total_actors BETWEEN 5 AND 10 THEN 'Medium'
        ELSE 'Low'
    END AS actor_count_category
FROM movie_hierarchy mh
JOIN movie_details md ON mh.movie_id = md.movie_id
LEFT JOIN cast_details cd ON mh.movie_id = cd.movie_id
GROUP BY mh.movie_id, mh.title, mh.production_year, md.keyword_count, md.companies, md.total_actors
ORDER BY mh.production_year DESC, md.total_actors DESC
LIMIT 50;
