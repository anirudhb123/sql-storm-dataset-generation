WITH movie_info_summary AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
        GROUP_CONCAT(DISTINCT cn.name) AS companies,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM
        title t
    LEFT JOIN
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN
        cast_info ci ON cc.subject_id = ci.id
    GROUP BY
        t.id, t.title, t.production_year
),
person_summary AS (
    SELECT
        p.id AS person_id,
        CONCAT(aka.name, ' (', a.title, ')') AS display_name,
        COUNT(DISTINCT c.movie_id) AS movies_involved,
        COUNT(DISTINCT pi.info_type_id) AS info_types
    FROM
        aka_name aka
    JOIN
        name p ON aka.person_id = p.id
    LEFT JOIN
        cast_info c ON p.id = c.person_id
    LEFT JOIN
        complete_cast cc ON c.movie_id = cc.movie_id
    LEFT JOIN
        title a ON cc.movie_id = a.id
    LEFT JOIN
        person_info pi ON p.id = pi.person_id
    GROUP BY
        p.id, aka.name, a.title
)
SELECT
    m.movie_id,
    m.title,
    m.production_year,
    m.keywords,
    m.companies,
    m.cast_count,
    ps.display_name,
    ps.movies_involved,
    ps.info_types
FROM
    movie_info_summary m
LEFT JOIN
    person_summary ps ON m.cast_count > 0
ORDER BY
    m.production_year DESC, m.title ASC;
