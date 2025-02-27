WITH movie_summary AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        GROUP_CONCAT(DISTINCT ak.name ORDER BY ak.name SEPARATOR ', ') AS cast_names,
        COUNT(DISTINCT kw.keyword) AS keyword_count
    FROM
        title t
    LEFT JOIN
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN
        cast_info c ON t.id = c.movie_id
    LEFT JOIN
        aka_name ak ON c.person_id = ak.person_id
    LEFT JOIN
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN
        keyword kw ON mk.keyword_id = kw.id
    GROUP BY
        t.id, t.title, t.production_year
),
movie_info_summary AS (
    SELECT
        movie_id,
        STRING_AGG(info, '; ') AS info_details
    FROM
        movie_info
    GROUP BY
        movie_id
)
SELECT
    ms.movie_id,
    ms.title,
    ms.production_year,
    ms.cast_count,
    ms.cast_names,
    ms.keyword_count,
    COALESCE(mis.info_details, 'No additional info') AS info_details
FROM
    movie_summary ms
LEFT JOIN
    movie_info_summary mis ON ms.movie_id = mis.movie_id
WHERE
    ms.production_year > 2000
ORDER BY
    ms.production_year DESC, ms.cast_count DESC;
