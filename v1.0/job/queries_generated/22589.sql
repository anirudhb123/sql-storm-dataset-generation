WITH RECURSIVE movie_hierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        1 AS level
    FROM
        aka_title mt
    WHERE
        mt.production_year IS NOT NULL
    UNION ALL
    SELECT
        m.linked_movie_id,
        m2.title,
        m2.production_year,
        m2.kind_id,
        mh.level + 1
    FROM
        movie_link m
    JOIN
        aka_title m2 ON m.linked_movie_id = m2.id
    JOIN
        movie_hierarchy mh ON m.movie_id = mh.movie_id
),
name_counts AS (
    SELECT
        n.name,
        COUNT(ci.id) AS role_count
    FROM
        name n
    LEFT JOIN
        cast_info ci ON n.imdb_id = ci.person_id
    GROUP BY
        n.name
    HAVING
        COUNT(ci.id) > 1
),
keyword_summary AS (
    SELECT
        mk.keyword,
        COUNT(DISTINCT mt.id) AS movie_count
    FROM
        movie_keyword mk
    JOIN
        aka_title mt ON mk.movie_id = mt.id
    GROUP BY
        mk.keyword
    HAVING
        COUNT(DISTINCT mt.id) > 5
),
movie_details AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        coalesce(k.keyword, 'No keywords') AS keyword,
        COALESCE(CAST((SELECT STRING_AGG(n.name, ', ') 
                       FROM name n 
                       JOIN cast_info c ON n.imdb_id = c.person_id 
                       WHERE c.movie_id = m.id) AS text), '') , 'No actors') AS actors
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE
        m.production_year = (SELECT MAX(production_year) FROM aka_title) -- Filter for the most recent movies
)
SELECT
    mh.movie_id,
    mh.title, 
    mh.production_year,
    mh.level,
    md.keyword,
    md.actors,
    nc.name,
    nc.role_count
FROM
    movie_hierarchy mh
LEFT JOIN  
    movie_details md ON mh.movie_id = md.movie_id
LEFT JOIN 
    name_counts nc ON md.actors ILIKE '%' || nc.name || '%'
WHERE
    (mh.production_year IS NOT NULL OR md.keyword IS NOT NULL) -- Ensuring relevant records
    AND mh.level < 3 -- Limiting to a depth of 3 in the hierarchy
ORDER BY
    mh.production_year DESC, mh.level, md.keyword NULLS LAST;

