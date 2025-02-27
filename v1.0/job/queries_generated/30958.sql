WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS depth
    FROM aka_title mt
    WHERE production_year >= 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.depth + 1
    FROM movie_link ml
    JOIN aka_title at ON ml.linked_movie_id = at.id
    JOIN movie_hierarchy mh ON ml.movie_id = mh.movie_id
),
cast_with_rank AS (
    SELECT 
        ci.id,
        ci.movie_id,
        ci.person_id,
        ci.note,
        RANK() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS role_rank
    FROM cast_info ci
),
avg_cast_roles AS (
    SELECT
        mh.movie_id,
        AVG(role_rank) AS avg_role_rank
    FROM movie_hierarchy mh
    LEFT JOIN cast_with_rank cr ON mh.movie_id = cr.movie_id
    GROUP BY mh.movie_id
),
popular_keywords AS (
    SELECT 
        mk.movie_id,
        k.keyword,
        COUNT(k.id) AS keyword_count
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id, k.keyword
    HAVING COUNT(k.id) > 5
)
SELECT 
    mh.title,
    mh.production_year,
    acj.name AS actor_name,
    ar.avg_role_rank,
    pk.keyword,
    pk.keyword_count
FROM movie_hierarchy mh
LEFT JOIN cast_with_rank cr ON mh.movie_id = cr.movie_id
LEFT JOIN aka_name acj ON cr.person_id = acj.person_id
LEFT JOIN avg_cast_roles ar ON mh.movie_id = ar.movie_id
LEFT JOIN popular_keywords pk ON mh.movie_id = pk.movie_id
WHERE mh.depth = 1
AND (ar.avg_role_rank IS NULL OR ar.avg_role_rank < 2)
ORDER BY mh.production_year DESC, mh.title;
