
WITH RECURSIVE MovieHierarchy AS (
    
    SELECT
        ml.movie_id,
        ml.linked_movie_id,
        1 AS level
    FROM
        movie_link ml
    WHERE
        ml.link_type_id = (SELECT id FROM link_type WHERE link = 'Sequel')

    UNION ALL

    SELECT
        mh.movie_id,
        ml.linked_movie_id,
        mh.level + 1
    FROM
        MovieHierarchy mh
    JOIN
        movie_link ml ON mh.linked_movie_id = ml.movie_id
    WHERE
        ml.link_type_id = (SELECT id FROM link_type WHERE link = 'Sequel')
),

DistinctMovies AS (
    SELECT
        m.production_year,
        m.title,
        ak.name AS actor_name
    FROM
        aka_title m
    JOIN
        complete_cast cc ON m.id = cc.movie_id
    JOIN
        cast_info ci ON cc.subject_id = ci.person_id
    JOIN
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY
        m.production_year, m.title, ak.name
)


SELECT
    dm.production_year,
    dm.title,
    ARRAY_AGG(DISTINCT dm.actor_name) AS actors,
    COUNT(*) OVER (PARTITION BY dm.production_year) AS movie_count,
    COALESCE(mh.level, 0) AS sequel_level
FROM
    DistinctMovies dm
LEFT JOIN
    MovieHierarchy mh ON dm.title = (SELECT title FROM aka_title WHERE movie_id = mh.linked_movie_id LIMIT 1)
WHERE
    dm.production_year IS NOT NULL
AND
    DATE_PART('YEAR', '2024-10-01'::DATE) - dm.production_year < 10  
GROUP BY
    dm.production_year, dm.title, mh.level
ORDER BY
    dm.production_year DESC, movie_count DESC;
