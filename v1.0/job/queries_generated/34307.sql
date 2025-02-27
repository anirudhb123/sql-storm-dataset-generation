WITH RECURSIVE movie_hierarchy AS (
    SELECT
        m.movie_id,
        m.title,
        1 AS level,
        ARRAY[m.movie_id] AS path
    FROM
        aka_title m
    WHERE
        m.production_year >= 2000
    UNION ALL
    SELECT
        ml.linked_movie_id,
        mt.title,
        mh.level + 1,
        path || ml.linked_movie_id
    FROM
        movie_link ml
    JOIN
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    JOIN
        aka_title mt ON ml.linked_movie_id = mt.movie_id
    WHERE
        mt.production_year >= 2000 AND
        NOT ml.linked_movie_id = ANY(mh.path)
),
actor_info AS (
    SELECT
        a.id AS actor_id,
        ak.name AS actor_name,
        COUNT(DISTINCT c.movie_id) AS film_count
    FROM
        cast_info c
    JOIN
        aka_name ak ON c.person_id = ak.person_id
    GROUP BY
        ak.id, ak.name
),
movie_details AS (
    SELECT
        mh.movie_id,
        mh.title,
        mh.level,
        COALESCE(ki.keyword, 'Unknown') AS keyword,
        ARRAY_REMOVE(ARRAY_AGG(ai.actor_name), NULL) AS cast_names
    FROM
        movie_hierarchy mh
    LEFT JOIN
        movie_keyword mk ON mh.movie_id = mk.movie_id
    LEFT JOIN
        keyword ki ON mk.keyword_id = ki.id
    LEFT JOIN
        movie_companies mc ON mh.movie_id = mc.movie_id
    LEFT JOIN
        actor_info ai ON mc.movie_id = ai.actor_id
    WHERE
        mh.level <= 3
    GROUP BY
        mh.movie_id, mh.title, mh.level, ki.keyword
)
SELECT
    md.movie_id,
    md.title,
    md.level,
    md.keyword,
    md.cast_names,
    COALESCE(director.dr_name, 'Unknown') AS director_name,
    CASE 
        WHEN COUNT(DISTINCT mc.company_id) > 0 THEN 'Multiple Companies'
        ELSE 'Single Company'
    END AS company_status
FROM
    movie_details md
LEFT JOIN (
    SELECT
        mc.movie_id,
        cn.name AS dr_name
    FROM
        movie_companies mc
    JOIN
        company_name cn ON mc.company_id = cn.id
    WHERE
        mc.company_type_id = (SELECT id FROM company_type WHERE kind = 'Director')
) director ON md.movie_id = director.movie_id
LEFT JOIN
    movie_companies mc ON md.movie_id = mc.movie_id
WHERE
    md.level = 3
GROUP BY
    md.movie_id, md.title, md.level, md.keyword, director.dr_name
ORDER BY
    md.level DESC, md.title;
