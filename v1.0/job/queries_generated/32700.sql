WITH RECURSIVE movie_hierarchy AS (
    SELECT mt.id AS movie_id, mt.title, mt.production_year, 1 AS depth
    FROM aka_title mt
    WHERE mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL

    SELECT m.id AS movie_id, m.title, m.production_year, mh.depth + 1
    FROM aka_title m
    JOIN movie_link ml ON m.id = ml.linked_movie_id
    JOIN movie_hierarchy mh ON ml.movie_id = mh.movie_id
),
cast_summary AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        COUNT(ci.movie_id) AS movies_count,
        AVG(COALESCE(m.production_year, 0)) AS average_year
    FROM aka_name a
    LEFT JOIN cast_info ci ON a.person_id = ci.person_id
    LEFT JOIN aka_title m ON ci.movie_id = m.id
    WHERE a.name IS NOT NULL
    GROUP BY a.id, a.name
),
movie_keywords AS (
    SELECT 
        mt.id AS movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM aka_title mt
    LEFT JOIN movie_keyword mk ON mt.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mt.id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    cs.actor_name,
    cs.movies_count,
    cs.average_year,
    mk.keywords
FROM movie_hierarchy mh
LEFT JOIN cast_summary cs ON cs.movies_count > 5
LEFT JOIN movie_keywords mk ON mh.movie_id = mk.movie_id
ORDER BY mh.production_year DESC, cs.movies_count DESC;

This SQL query showcases several advanced constructs and features:
- A recursive common table expression (CTE) `movie_hierarchy` that builds a hierarchy of movies.
- A `cast_summary` CTE that aggregates data about actors, calculating counts and averages.
- A `movie_keywords` CTE that collects keywords associated with each movie.
- The main SELECT statement pulls data from these CTEs, applying filters, GROUP BY, and STRING_AGG for concatenating keywords.
- It includes various joins and NULL handling with `COALESCE`.
- The results are ordered by production year and actor's movie count.
