WITH RECURSIVE movie_hierarchy AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM
        aka_title m
    WHERE
        m.production_year IS NOT NULL

    UNION ALL

    SELECT
        m2.id AS movie_id,
        m2.title,
        m2.production_year,
        mh.level + 1
    FROM
        movie_hierarchy mh
    JOIN
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN
        aka_title m2 ON ml.linked_movie_id = m2.id
)

SELECT
    ak.name AS actor_name,
    m.title AS movie_title,
    year_over_year_change,
    CAST(COALESCE(experience, 0) AS TEXT) AS actor_experience,
    CASE 
        WHEN ac.note IS NULL THEN 'No note provided'
        ELSE ac.note
    END AS actor_note,
    ROW_NUMBER() OVER(PARTITION BY ak.id ORDER BY m.production_year DESC) AS movie_rank
FROM
    aka_name ak
JOIN
    cast_info ci ON ak.person_id = ci.person_id
JOIN
    aka_title m ON ci.movie_id = m.id
LEFT JOIN
    (SELECT
        movie_id,
        SUM(CASE WHEN year >= 2021 THEN 1 ELSE 0 END) AS year_over_year_change,
        COUNT(*) AS experience,
        movie_id AS sub_movie_id
     FROM
         movie_info mi
     GROUP BY
         movie_id
    ) exp ON m.id = exp.movie_id
LEFT JOIN
    complete_cast cc ON m.id = cc.movie_id
LEFT JOIN
    (SELECT
        movie_id,
        STRING_AGG(note, ', ') AS note
     FROM
         cast_info
     GROUP BY
         movie_id
    ) ac ON m.id = ac.movie_id
WHERE
    ak.name LIKE 'A%' AND
    (m.production_year < 2020 OR m.production_year IS NULL)
ORDER BY
    ak.name, m.production_year DESC
FETCH FIRST 100 ROWS ONLY;
