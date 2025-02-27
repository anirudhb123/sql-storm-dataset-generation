WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        1 AS level
    FROM aka_title mt
    WHERE mt.production_year >= 2000  -- Start from year 2000

    UNION ALL

    SELECT 
        mv.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        at.kind_id,
        mh.level + 1 AS level
    FROM movie_link mv
    JOIN aka_title at ON mv.linked_movie_id = at.id
    JOIN movie_hierarchy mh ON mv.movie_id = mh.movie_id
    WHERE mh.level < 3  -- Limit to 3 levels deep
),
cast_roles AS (
    SELECT 
        ci.person_id,
        ct.kind AS role,
        COUNT(*) AS count_roles
    FROM cast_info ci
    JOIN comp_cast_type ct ON ci.person_role_id = ct.id
    GROUP BY ci.person_id, ct.kind
),
ranked_movies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        RANK() OVER (PARTITION BY mh.kind_id ORDER BY mh.production_year DESC) AS rank
    FROM movie_hierarchy mh
)
SELECT 
    ak.name AS actor_name,
    rm.title AS movie_title,
    rm.production_year,
    cr.role AS cast_role,
    cr.count_roles,
    COALESCE(ek.movie_id, 0) AS external_movie_id,
    (SELECT COUNT(*) FROM movie_keyword mk WHERE mk.movie_id = rm.movie_id) AS keyword_count
FROM ranked_movies rm
JOIN cast_info ci ON ci.movie_id = rm.movie_id
JOIN aka_name ak ON ak.person_id = ci.person_id
JOIN cast_roles cr ON cr.person_id = ci.person_id
LEFT JOIN movie_link ml ON ml.movie_id = rm.movie_id
LEFT JOIN aka_title ek ON ek.id = ml.linked_movie_id
WHERE rm.rank <= 5 
AND rm.production_year IS NOT NULL
ORDER BY rm.production_year DESC, actor_name;
