WITH ranked_movies AS (
    SELECT
        t.title,
        t.production_year,
        ARRAY_AGG(DISTINCT ak.name) AS aka_names,
        COUNT(DISTINCT cc.person_id) AS cast_count,
        COUNT(DISTINCT mk.keyword) AS keyword_count
    FROM
        aka_title AS t
    JOIN
        aka_name AS ak ON ak.id = t.id
    LEFT JOIN
        cast_info AS cc ON cc.movie_id = t.movie_id
    LEFT JOIN
        movie_keyword AS mk ON mk.movie_id = t.movie_id
    WHERE
        t.production_year >= 2000
    GROUP BY
        t.id, t.title, t.production_year
),
extended_movie_info AS (
    SELECT
        rm.title,
        rm.production_year,
        COALESCE(NULLIF(array_to_string(rm.aka_names, ', '), ''), 'No Alternate Names') AS alternate_names,
        rm.cast_count,
        COALESCE(NULLIF(mo.info, ''), 'No Info Available') AS movie_info,
        CASE WHEN rm.cast_count > 0 THEN 'Has Cast' ELSE 'No Cast' END AS cast_status
    FROM
        ranked_movies AS rm
    LEFT JOIN
        movie_info AS mo ON mo.movie_id = rm.movie_id
    WHERE
        rm.keyword_count > 2
)
SELECT
    emi.title,
    emi.production_year,
    emi.alternate_names,
    emi.cast_count,
    emi.movie_info,
    emi.cast_status
FROM
    extended_movie_info AS emi
ORDER BY
    emi.production_year DESC, emi.cast_count DESC;
