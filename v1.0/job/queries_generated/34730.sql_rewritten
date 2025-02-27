WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        m.kind_id,
        1 AS level
    FROM title m
    WHERE m.production_year >= 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        t.title,
        t.production_year,
        t.kind_id,
        mh.level + 1
    FROM movie_link ml
    JOIN title t ON ml.linked_movie_id = t.id
    JOIN movie_hierarchy mh ON ml.movie_id = mh.movie_id
    WHERE mh.level < 5
),
cast_role_counts AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        ARRAY_AGG(DISTINCT r.role) AS roles
    FROM cast_info ci
    JOIN role_type r ON ci.role_id = r.id
    GROUP BY ci.movie_id
),
keyword_aggregates AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
),
movie_details AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        mh.kind_id,
        coalesce(cc.cast_count, 0) AS cast_count,
        coalesce(ka.keywords, 'No keywords') AS keywords,
        mh.level
    FROM movie_hierarchy mh
    LEFT JOIN cast_role_counts cc ON mh.movie_id = cc.movie_id
    LEFT JOIN keyword_aggregates ka ON mh.movie_id = ka.movie_id
)
SELECT 
    md.title,
    md.production_year,
    md.cast_count,
    md.keywords,
    k.kind AS movie_type
FROM movie_details md
JOIN kind_type k ON md.kind_id = k.id
WHERE md.cast_count > 2 
ORDER BY md.production_year DESC, md.cast_count DESC
LIMIT 10;