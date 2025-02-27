WITH RECURSIVE movie_hierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        CAST(NULL AS text) AS parent_title,
        mt.production_year,
        0 AS depth
    FROM
        aka_title mt
    WHERE
        mt.season_nr IS NULL

    UNION ALL

    SELECT
        et.id AS movie_id,
        et.title,
        mh.title AS parent_title,
        et.production_year,
        mh.depth + 1
    FROM
        aka_title et
    JOIN
        movie_hierarchy mh ON et.episode_of_id = mh.movie_id
),

cast_details AS (
    SELECT
        ci.movie_id,
        COUNT(ci.id) AS cast_count,
        STRING_AGG(aka.name, ', ') AS cast_names
    FROM
        cast_info ci
    JOIN
        aka_name aka ON ci.person_id = aka.person_id
    GROUP BY
        ci.movie_id
),

keyword_summary AS (
    SELECT
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM
        movie_keyword mk
    JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        mk.movie_id
)

SELECT
    mh.movie_id,
    mh.title,
    mh.production_year,
    c.cast_count,
    c.cast_names,
    k.keywords,
    CASE 
        WHEN mh.depth = 0 THEN 'Standalone Movie' 
        ELSE 'Episode of ' || mh.parent_title 
    END AS movie_type,
    COALESCE(nt.name, 'Unknown') AS movie_type_name
FROM
    movie_hierarchy mh
LEFT JOIN
    cast_details c ON mh.movie_id = c.movie_id
LEFT JOIN
    keyword_summary k ON mh.movie_id = k.movie_id
LEFT JOIN
    title nt ON mh.movie_id = nt.id
WHERE
    mh.depth < 2 AND
    (mh.production_year > 2000 OR mh.title LIKE '%Legend%')
ORDER BY
    mh.production_year DESC,
    mh.title ASC
LIMIT 100 OFFSET 0;

-- This query creates a recursive CTE to construct a hierarchy of movies and episodes, 
-- gathers cast details, and aggregates keywords, 
-- while applying various filters and transformations for performance benchmarking.
