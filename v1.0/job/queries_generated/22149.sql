WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS depth,
        mt.episode_of_id
    FROM aka_title mt
    WHERE mt.production_year IS NOT NULL

    UNION ALL

    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mh.depth + 1,
        mt.episode_of_id
    FROM aka_title mt
    INNER JOIN movie_hierarchy mh ON mt.episode_of_id = mh.movie_id
),
cast_summary AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        STRING_AGG(DISTINCT ak.name, ', ') AS cast_members
    FROM cast_info ci
    JOIN aka_name ak ON ak.person_id = ci.person_id
    GROUP BY ci.movie_id
),
keyword_summary AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, '; ') AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON k.id = mk.keyword_id
    GROUP BY mk.movie_id
),
movie_info_summary AS (
    SELECT 
        mi.movie_id,
        COUNT(*) AS info_count,
        MAX(CASE WHEN it.info = 'Budget' THEN mi.info ELSE NULL END) AS budget_info
    FROM movie_info mi
    JOIN info_type it ON it.id = mi.info_type_id
    GROUP BY mi.movie_id
),
final_summary AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COALESCE(cs.total_cast, 0) AS total_cast,
        COALESCE(cs.cast_members, 'No Cast') AS cast_members,
        COALESCE(ks.keywords, 'No Keywords') AS keywords,
        COALESCE(mis.info_count, 0) AS info_count,
        COALESCE(mis.budget_info, 'No Budget Info') AS budget_info
    FROM movie_hierarchy mh
    LEFT JOIN cast_summary cs ON cs.movie_id = mh.movie_id
    LEFT JOIN keyword_summary ks ON ks.movie_id = mh.movie_id
    LEFT JOIN movie_info_summary mis ON mis.movie_id = mh.movie_id
)
SELECT 
    *,
    CASE
        WHEN total_cast > 5 THEN 'Large Cast'
        WHEN total_cast BETWEEN 3 AND 5 THEN 'Medium Cast'
        ELSE 'Small Cast'
    END AS cast_size,
    (CASE 
        WHEN production_year IS NULL THEN 'Unknown Year'
        ELSE 'Year Known'
    END) AS year_info
FROM final_summary
WHERE 
    production_year >= 2000
    AND (keywords IS NOT NULL OR keywords LIKE '%Action%')
ORDER BY depth, total_cast DESC, title ASC;
