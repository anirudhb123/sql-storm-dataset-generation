WITH movie_info_aggregated AS (
    SELECT
        mi.movie_id,
        STRING_AGG(DISTINCT mi.info, '; ') AS aggregated_info,
        COUNT(DISTINCT mi.info_type_id) AS info_type_count
    FROM
        movie_info mi
    GROUP BY
        mi.movie_id
),
cast_info_aggregated AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        STRING_AGG(DISTINCT cm.kind, ', ') AS cast_roles
    FROM
        cast_info ci
    JOIN
        comp_cast_type cm ON ci.person_role_id = cm.id
    GROUP BY
        ci.movie_id
),
title_info AS (
    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        ka.name AS actor_name,
        ka.person_id,
        k.keyword AS keywords
    FROM
        title t
    JOIN
        aka_title at ON t.id = at.movie_id
    JOIN
        cast_info ci ON t.id = ci.movie_id
    JOIN
        aka_name ka ON ci.person_id = ka.person_id
    LEFT JOIN
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN
        keyword k ON mk.keyword_id = k.id
    WHERE
        t.production_year >= 2000
),
final_benchmark AS (
    SELECT
        ti.title_id,
        ti.title,
        ti.production_year,
        ca.total_cast,
        ca.cast_roles,
        ma.aggregated_info,
        ma.info_type_count,
        STRING_AGG(DISTINCT ti.keywords, ', ') AS all_keywords
    FROM
        title_info ti
    LEFT JOIN
        cast_info_aggregated ca ON ti.title_id = ca.movie_id
    LEFT JOIN
        movie_info_aggregated ma ON ti.title_id = ma.movie_id
    GROUP BY
        ti.title_id, ti.title, ti.production_year, ca.total_cast, ca.cast_roles, ma.aggregated_info, ma.info_type_count
)
SELECT
    *,
    ROW_NUMBER() OVER (ORDER BY production_year DESC, total_cast DESC) AS rank
FROM
    final_benchmark
ORDER BY
    rank;
