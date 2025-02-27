WITH recursive movie_hierarchy AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        0 AS level
    FROM
        aka_title AS m
    WHERE
        m.production_year IS NOT NULL
    
    UNION ALL

    SELECT
        ml.linked_movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM
        movie_link AS ml
    JOIN
        aka_title AS m ON ml.linked_movie_id = m.id
    JOIN
        movie_hierarchy AS mh ON ml.movie_id = mh.movie_id
    WHERE
        mh.level < 5  -- limit the depth of recursion to 5 levels
),

movie_keywords AS (
    SELECT
        m.id AS movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM
        aka_title AS m
    LEFT JOIN
        movie_keyword AS mk ON m.id = mk.movie_id
    LEFT JOIN
        keyword AS k ON mk.keyword_id = k.id
    GROUP BY
        m.id
),

starring_info AS (
    SELECT
        c.movie_id,
        STRING_AGG(DISTINCT CONCAT(a.name, ' as ', r.role), ', ') AS cast_details
    FROM
        cast_info AS c
    JOIN
        aka_name AS a ON c.person_id = a.person_id
    JOIN
        role_type AS r ON c.role_id = r.id
    GROUP BY
        c.movie_id
),

final_report AS (
    SELECT
        m.id AS movie_id,
        m.title,
        COALESCE(mh.level, 0) AS hierarchy_level,
        COALESCE(mk.keywords, 'No keywords') AS keywords,
        COALESCE(si.cast_details, 'No cast information') AS cast_details
    FROM
        aka_title AS m
    LEFT JOIN
        movie_hierarchy AS mh ON m.id = mh.movie_id
    LEFT JOIN
        movie_keywords AS mk ON m.id = mk.movie_id
    LEFT JOIN
        starring_info AS si ON m.id = si.movie_id
    WHERE
        m.production_year BETWEEN 2000 AND 2023
)

SELECT
    f.movie_id,
    f.title,
    f.hierarchy_level,
    f.keywords,
    f.cast_details,
    CASE 
        WHEN f.hierarchy_level = 0 THEN 'Original Movie'
        WHEN f.hierarchy_level BETWEEN 1 AND 3 THEN 'Sequel/Prequel'
        ELSE 'Franchise'
    END AS movie_type,
    COUNT(DISTINCT si.cast_details) OVER (PARTITION BY f.hierarchy_level) AS cast_count_by_level
FROM
    final_report AS f
LEFT JOIN
    starring_info AS si ON f.movie_id = si.movie_id
WHERE
    f.cast_details IS NOT NULL
ORDER BY
    f.hierarchy_level, f.title;
