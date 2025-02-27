WITH RECURSIVE movie_hierarchy AS (
    SELECT m.id AS movie_id, m.title, 1 AS depth
    FROM aka_title m
    WHERE m.production_year >= 2000
    UNION ALL
    SELECT m.id, m.title, mh.depth + 1
    FROM aka_title m
    JOIN movie_link ml ON ml.linked_movie_id = m.id
    JOIN movie_hierarchy mh ON mh.movie_id = ml.movie_id
), 
cast_summary AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names
    FROM cast_info ci
    JOIN aka_name a ON a.person_id = ci.person_id
    GROUP BY ci.movie_id
),
movie_info_summary AS (
    SELECT 
        mi.movie_id,
        COUNT(DISTINCT mi.info_type_id) AS info_count,
        MAX(mi.info) AS latest_info
    FROM movie_info mi
    GROUP BY mi.movie_id
),
ranked_movies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        ms.total_cast,
        mi.info_count,
        ROW_NUMBER() OVER (PARTITION BY mh.depth ORDER BY ms.total_cast DESC) AS rank
    FROM movie_hierarchy mh
    LEFT JOIN cast_summary ms ON mh.movie_id = ms.movie_id
    LEFT JOIN movie_info_summary mi ON mh.movie_id = mi.movie_id
)

SELECT 
    rm.title,
    rm.total_cast,
    rm.info_count,
    COALESCE(rm.rank, 0) AS rank,
    CASE 
        WHEN rm.total_cast IS NULL THEN 'No cast information'
        WHEN rm.total_cast = 0 THEN 'Empty cast'
        ELSE 'Has cast'
    END AS cast_status
FROM ranked_movies rm
WHERE rm.rank <= 5 OR rm.total_cast IS NOT NULL
ORDER BY rm.total_cast DESC, rm.title;
