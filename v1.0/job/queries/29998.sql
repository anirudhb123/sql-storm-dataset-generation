WITH movie_info_agg AS (
    SELECT
        m.id AS movie_id,
        m.title,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords,
        ARRAY_AGG(DISTINCT c.name) AS companies,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM
        aka_title m
    LEFT JOIN
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN
        company_name c ON mc.company_id = c.id
    LEFT JOIN
        complete_cast cc ON m.id = cc.movie_id
    LEFT JOIN
        cast_info ci ON cc.subject_id = ci.id
    GROUP BY
        m.id, m.title
),
person_info_agg AS (
    SELECT
        p.person_id,
        ARRAY_AGG(DISTINCT pi.info) AS person_info
    FROM
        aka_name p
    LEFT JOIN
        person_info pi ON p.person_id = pi.person_id
    GROUP BY
        p.person_id
)
SELECT
    m.movie_id,
    m.title,
    m.keywords,
    m.companies,
    m.cast_count,
    p.person_info 
FROM
    movie_info_agg m
LEFT JOIN
    complete_cast cc ON m.movie_id = cc.movie_id
LEFT JOIN
    cast_info ci ON cc.subject_id = ci.id
LEFT JOIN
    person_info_agg p ON ci.person_id = p.person_id
WHERE
    m.cast_count > 5 
    AND m.keywords @> ARRAY['action', 'thriller'] 
ORDER BY
    m.cast_count DESC, m.title;
