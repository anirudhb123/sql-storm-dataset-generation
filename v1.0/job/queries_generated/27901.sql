WITH movie_details AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        ARRAY_AGG(DISTINCT c.name) AS cast_names,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords,
        ARRAY_AGG(DISTINCT cn.name) AS company_names,
        COALESCE(mi.info, 'No Info') AS additional_info
    FROM
        aka_title m
    LEFT JOIN
        complete_cast cc ON m.id = cc.movie_id
    LEFT JOIN
        cast_info ci ON cc.subject_id = ci.person_id
    LEFT JOIN
        aka_name c ON ci.person_id = c.person_id
    LEFT JOIN
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN
        movie_info mi ON m.id = mi.movie_id
    GROUP BY
        m.id, m.title, m.production_year, mi.info
),
role_summary AS (
    SELECT
        ci.movie_id,
        rt.role,
        COUNT(*) AS role_count
    FROM
        cast_info ci
    JOIN
        role_type rt ON ci.role_id = rt.id
    GROUP BY
        ci.movie_id, rt.role
)
SELECT
    md.movie_id,
    md.title,
    md.production_year,
    md.cast_names,
    md.keywords,
    md.company_names,
    md.additional_info,
    rs.role,
    rs.role_count
FROM
    movie_details md
LEFT JOIN
    role_summary rs ON md.movie_id = rs.movie_id
ORDER BY
    md.production_year DESC, md.title;
