WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS depth
    FROM title m
    WHERE m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')

    UNION ALL

    SELECT 
        lm.linked_movie_id AS movie_id,
        t.title,
        t.production_year,
        mh.depth + 1
    FROM movie_link lm
    JOIN movie_hierarchy mh ON mh.movie_id = lm.movie_id
    JOIN title t ON lm.linked_movie_id = t.id
    WHERE mh.depth < 5
),
ranked_movies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        RANK() OVER (PARTITION BY mh.production_year ORDER BY mh.depth) AS rank_depth
    FROM movie_hierarchy mh
),
cast_aggregates AS (
    SELECT 
        ci.movie_id,
        COUNT(ci.person_id) AS total_cast,
        STRING_AGG(an.name, ', ') AS cast_names
    FROM cast_info ci
    JOIN aka_name an ON ci.person_id = an.person_id
    GROUP BY ci.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    COALESCE(ca.total_cast, 0) AS total_cast,
    COALESCE(ca.cast_names, 'No cast listed') AS cast_names,
    CASE 
        WHEN rm.rank_depth > 10 THEN 'Low rank'
        WHEN rm.rank_depth BETWEEN 5 AND 10 THEN 'Medium rank'
        ELSE 'High rank'
    END AS rank_category
FROM ranked_movies rm
LEFT JOIN cast_aggregates ca ON rm.movie_id = ca.movie_id
WHERE rm.production_year >= 2000
ORDER BY rm.production_year DESC, rm.rank_depth;
