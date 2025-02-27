WITH RECURSIVE movie_hierarchy AS (
    -- Recursive CTE to build a hierarchy of movies and their linked movies
    SELECT
        ml.movie_id AS root_movie_id,
        ml.linked_movie_id,
        1 AS depth
    FROM
        movie_link ml
    WHERE
        ml.movie_id IS NOT NULL
    
    UNION ALL
    
    SELECT
        mh.root_movie_id,
        ml.linked_movie_id,
        mh.depth + 1
    FROM
        movie_hierarchy mh
    JOIN movie_link ml ON mh.linked_movie_id = ml.movie_id
),
movie_cast AS (
    -- CTE to select unique movies and their casts with role types
    SELECT
        mt.id AS movie_id,
        mt.title,
        STRING_AGG(DISTINCT ak.name, ', ') AS cast_names,
        STRING_AGG(DISTINCT rt.role, ', ') AS roles
    FROM
        aka_title mt
    LEFT JOIN cast_info ci ON mt.id = ci.movie_id
    LEFT JOIN aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN role_type rt ON ci.role_id = rt.id
    GROUP BY mt.id, mt.title
),
movie_keywords AS (
    -- CTE to get movies with their keywords
    SELECT
        mt.id AS movie_id,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords
    FROM
        aka_title mt
    LEFT JOIN movie_keyword mk ON mt.id = mk.movie_id
    LEFT JOIN keyword kw ON mk.keyword_id = kw.id
    GROUP BY mt.id
),
final_results AS (
    -- Combine movie information with additional details
    SELECT
        mc.movie_id,
        mc.title,
        mc.cast_names,
        mc.roles,
        mk.keywords,
        CASE
            WHEN mh.linked_movie_id IS NOT NULL THEN 'Linked'
            ELSE 'Standalone'
        END AS movie_type
    FROM
        movie_cast mc
    LEFT JOIN movie_keywords mk ON mc.movie_id = mk.movie_id
    LEFT JOIN movie_hierarchy mh ON mc.movie_id = mh.root_movie_id
)

SELECT
    fr.movie_id,
    fr.title,
    fr.cast_names,
    fr.roles,
    fr.keywords,
    fr.movie_type,
    COALESCE(mi.info, 'No additional info') AS additional_info
FROM
    final_results fr
LEFT JOIN movie_info mi ON fr.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Synopsis' LIMIT 1)
ORDER BY
    fr.title ASC,
    fr.movie_id;

This SQL query showcases various constructs, including a recursive CTE to build a hierarchy of movies linked through the `movie_link` table, grouping and aggregating cast information, keywords, and combining this with potential additional information from `movie_info`. It also utilizes outer joins, STRING_AGG for concatenating strings, and COALESCE to handle NULL values. The final result is ordered by title and movie ID.
