WITH RECURSIVE movie_hierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level,
        ARRAY[mt.title] AS title_path
    FROM
        aka_title mt
    WHERE
        mt.episode_of_id IS NULL  -- Start with top-level movies (not episodes)
    
    UNION ALL
    
    SELECT
        et.id AS movie_id,
        et.title,
        et.production_year,
        mh.level + 1,
        mh.title_path || et.title  -- Update path with episode title
    FROM
        aka_title et
    INNER JOIN
        movie_hierarchy mh ON et.episode_of_id = mh.movie_id  -- Recursive join
)

SELECT
    mk.keyword,
    COUNT(DISTINCT mh.movie_id) AS episode_count,
    AVG(CASE WHEN mh.level = 1 THEN 1 ELSE NULL END) AS avg_top_level_movies,
    COALESCE(SUM(mk.appearance_count), 0) AS total_keyword_appearances,
    ARRAY_AGG(DISTINCT mt.title) FILTER (WHERE mt.production_year = 2023) AS recent_titles,
    STRING_AGG(DISTINCT ak.name, ', ') AS actor_names
FROM
    movie_hierarchy mh
LEFT JOIN
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN
    movie_info mi ON mh.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Genre')
LEFT JOIN
    cast_info ci ON mh.movie_id = ci.movie_id
LEFT JOIN
    aka_name ak ON ci.person_id = ak.person_id
LEFT JOIN
    (SELECT
        movie_id,
        COUNT(*) AS appearance_count
     FROM
        movie_keyword
     GROUP BY
        movie_id) mk_counts ON mh.movie_id = mk_counts.movie_id
WHERE
    mk.keyword IS NOT NULL
GROUP BY
    mk.keyword
ORDER BY
    total_keyword_appearances DESC, avg_top_level_movies DESC;

This SQL query constructs a recursive common table expression (CTE) to gather information about movies and their episodes. It uses left joins to bring in related data, aggregates for counts and averages, and filters on specific criteria. The query is designed to benchmark performance by incorporating a complex structure with grouping, filtering, and various SQL functions.
