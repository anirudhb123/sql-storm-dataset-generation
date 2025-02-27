WITH ranked_titles AS (
    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank,
        COUNT(*) OVER (PARTITION BY t.production_year) AS total_titles,
        ct.kind AS title_kind
    FROM
        title t
    JOIN
        kind_type ct ON t.kind_id = ct.id
    WHERE
        t.production_year IS NOT NULL
),
person_roles AS (
    SELECT
        ci.person_id,
        ci.role_id,
        r.role,
        ROW_NUMBER() OVER (PARTITION BY ci.person_id ORDER BY ci.nr_order) AS role_rank
    FROM
        cast_info ci
    JOIN
        role_type r ON ci.role_id = r.id
),
title_keywords AS (
    SELECT
        mk.movie_id,
        k.keyword
    FROM
        movie_keyword mk
    JOIN
        keyword k ON mk.keyword_id = k.id
    WHERE
        k.keyword IS NOT NULL
),
info_summary AS (
    SELECT
        mi.movie_id,
        STRING_AGG(DISTINCT mi.info || ' (' || it.info || ')', '; ' ORDER BY it.info) AS aggregated_info
    FROM
        movie_info mi
    JOIN
        info_type it ON mi.info_type_id = it.id
    GROUP BY
        mi.movie_id
),
merged_data AS (
    SELECT
        rt.title_id,
        rt.title,
        rt.production_year,
        rt.title_kind,
        pr.person_id,
        pr.role,
        tk.keyword,
        isum.aggregated_info
    FROM
        ranked_titles rt
    LEFT JOIN
        person_roles pr ON pr.role_rank = 1
    LEFT JOIN
        title_keywords tk ON tk.movie_id = rt.title_id
    LEFT JOIN
        info_summary isum ON isum.movie_id = rt.title_id
)
SELECT
    md.title_id,
    md.title,
    md.production_year,
    md.title_kind,
    md.person_id,
    COALESCE(md.role, 'Unknown Role') AS role,
    STRING_AGG(md.keyword, ', ') AS keywords,
    CASE 
        WHEN md.aggregated_info IS NULL THEN 'No Info Available'
        ELSE md.aggregated_info
    END AS info_summary
FROM
    merged_data md
GROUP BY
    md.title_id, md.title, md.production_year, md.title_kind, md.person_id, md.role, md.aggregated_info
HAVING
    md.production_year >= 2020
ORDER BY
    md.production_year DESC, md.title;
