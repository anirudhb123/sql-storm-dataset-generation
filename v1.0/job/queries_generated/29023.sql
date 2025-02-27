WITH movie_keywords AS (
    SELECT
        mk.movie_id,
        array_agg(k.keyword) AS keywords,
        COUNT(DISTINCT k.id) AS keyword_count
    FROM
        movie_keyword mk
    JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        mk.movie_id
),
cast_details AS (
    SELECT
        ci.movie_id,
        array_agg(DISTINCT ak.name) AS cast_names,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM
        cast_info ci
    JOIN
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY
        ci.movie_id
),
company_details AS (
    SELECT
        mc.movie_id,
        array_agg(DISTINCT cn.name) AS company_names,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM
        movie_companies mc
    JOIN
        company_name cn ON mc.company_id = cn.id
    GROUP BY
        mc.movie_id
),
movie_info_full AS (
    SELECT
        mi.movie_id,
        jsonb_object_agg(it.info || ' (' || mi.note || ')' ) AS info_details
    FROM
        movie_info mi
    JOIN
        info_type it ON mi.info_type_id = it.id
    GROUP BY
        mi.movie_id
)
SELECT
    title.title,
    title.production_year,
    COALESCE(mk.keywords, '{}') AS keywords,
    COALESCE(cd.cast_names, '{}') AS cast_names,
    COALESCE(cd.cast_count, 0) AS cast_count,
    COALESCE(co.company_names, '{}') AS company_names,
    COALESCE(co.company_count, 0) AS company_count,
    COALESCE(mif.info_details, '{}'::jsonb) AS info_details
FROM
    title
LEFT JOIN
    movie_keywords mk ON title.id = mk.movie_id
LEFT JOIN
    cast_details cd ON title.id = cd.movie_id
LEFT JOIN
    company_details co ON title.id = co.movie_id
LEFT JOIN
    movie_info_full mif ON title.id = mif.movie_id
WHERE
    title.production_year >= 2000
ORDER BY
    title.production_year DESC,
    title.title ASC
LIMIT 50;
