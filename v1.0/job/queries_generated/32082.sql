WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id, 
        mt.title, 
        mt.production_year, 
        mt.kind_id, 
        1 AS depth
    FROM aka_title AS mt
    WHERE mt.episode_of_id IS NULL
    UNION ALL
    SELECT 
        e.id AS movie_id, 
        e.title, 
        e.production_year, 
        e.kind_id, 
        mh.depth + 1
    FROM aka_title AS e
    JOIN movie_hierarchy AS mh ON e.episode_of_id = mh.movie_id
),
ranked_cast AS (
    SELECT 
        ci.movie_id,
        ci.person_id,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS role_rank
    FROM cast_info AS ci
)
SELECT 
    mh.movie_id,
    mh.title AS movie_title,
    mh.production_year,
    COALESCE(arr.cast_names, 'None') AS cast_names,
    COALESCE(kw.keywords, 'None') AS keywords,
    mh.depth,
    CASE 
        WHEN mh.depth = 1 THEN 'Main'
        ELSE 'Episode'
    END AS movie_type
FROM movie_hierarchy AS mh
LEFT JOIN (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT ak.name, ', ') AS cast_names
    FROM ranked_cast AS rc
    JOIN aka_name AS ak ON rc.person_id = ak.person_id
    GROUP BY mc.movie_id
) AS arr ON mh.movie_id = arr.movie_id
LEFT JOIN (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM movie_keyword AS mk
    JOIN keyword AS k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
) AS kw ON mh.movie_id = kw.movie_id
WHERE 
    mh.production_year >= 2000
    AND mh.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
ORDER BY 
    mh.production_year DESC, 
    mh.title;

This SQL query utilizes various advanced constructs to benchmark performance, including:

- **CTE (Common Table Expressions)** for recursive hierarchies, capturing series and episodes.
- **Window Functions** for ranking cast roles.
- **LEFT JOINs** to aggregate additional data from cast and keywords.
- **STRING_AGG** for string manipulation, concatenating names and keywords.
- **COALESCE** for handling NULL values.
- **Filtering and Sorting** based on production year and kind type. 

This complex query is designed to analyze and extract rich information about movies while showcasing various SQL capabilities.
