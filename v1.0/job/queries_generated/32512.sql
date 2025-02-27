WITH RECURSIVE movie_hierarchy AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        m.kind_id,
        1 AS depth
    FROM title m
    WHERE m.production_year >= 2000
    
    UNION ALL
    
    SELECT
        ml.linked_movie_id,
        t.title,
        t.production_year,
        t.kind_id,
        mh.depth + 1
    FROM movie_link ml
    JOIN title t ON ml.linked_movie_id = t.id
    JOIN movie_hierarchy mh ON ml.movie_id = mh.movie_id
    WHERE t.production_year >= 2000 AND mh.depth < 5
),
cast_summary AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        MAX(CASE WHEN r.role = 'Director' THEN 'Yes' ELSE 'No' END) AS has_director,
        STRING_AGG(DISTINCT CONCAT(a.name, ' (', r.role, ')'), '; ') AS actor_roles
    FROM cast_info ci
    JOIN role_type r ON ci.role_id = r.id
    JOIN aka_name a ON ci.person_id = a.person_id
    GROUP BY ci.movie_id
),
company_info AS (
    SELECT
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies,
        STRING_AGG(DISTINCT ct.kind, ', ') AS company_types
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    GROUP BY mc.movie_id
)
SELECT
    mh.movie_id,
    mh.title,
    mh.production_year,
    mh.kind_id,
    cs.total_cast,
    cs.has_director,
    cs.actor_roles,
    ci.companies,
    ci.company_types,
    ROW_NUMBER() OVER (PARTITION BY mh.kind_id ORDER BY mh.production_year DESC) AS rn
FROM movie_hierarchy mh
LEFT JOIN cast_summary cs ON mh.movie_id = cs.movie_id
LEFT JOIN company_info ci ON mh.movie_id = ci.movie_id
WHERE mh.depth <= 2
ORDER BY mh.production_year DESC, mh.title;
