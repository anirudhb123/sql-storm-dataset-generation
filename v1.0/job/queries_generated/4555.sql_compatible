
WITH movie_data AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT mc.company_id) AS company_count,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies
    FROM
        aka_title t
    LEFT JOIN
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN
        company_name cn ON mc.company_id = cn.id
    WHERE
        t.production_year IS NOT NULL
        AND t.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE '%feature%')
    GROUP BY
        t.id, t.title, t.production_year
),
cast_data AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS cast_names
    FROM
        cast_info ci
    INNER JOIN
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY
        ci.movie_id
),
info_data AS (
    SELECT
        mi.movie_id,
        MAX(CASE WHEN it.info = 'budget' THEN mi.info ELSE NULL END) AS budget,
        MAX(CASE WHEN it.info = 'duration' THEN mi.info ELSE NULL END) AS duration
    FROM
        movie_info mi
    JOIN
        info_type it ON mi.info_type_id = it.id
    GROUP BY
        mi.movie_id
)
SELECT
    md.movie_id,
    md.title,
    md.production_year,
    COALESCE(md.company_count, 0) AS company_count,
    COALESCE(md.companies, 'No Companies') AS companies,
    COALESCE(cd.cast_count, 0) AS cast_count,
    COALESCE(cd.cast_names, 'No Cast') AS cast_names,
    COALESCE(id.budget, 'Unknown') AS budget,
    COALESCE(id.duration, 'Unknown') AS duration
FROM
    movie_data md
LEFT JOIN
    cast_data cd ON md.movie_id = cd.movie_id
LEFT JOIN
    info_data id ON md.movie_id = id.movie_id
WHERE
    md.production_year >= 2000
ORDER BY
    md.production_year DESC, md.title
LIMIT 50 OFFSET 0;
