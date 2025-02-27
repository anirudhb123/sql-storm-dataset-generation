
WITH movie_with_keywords AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        ARRAY_AGG(k.keyword) AS keywords
    FROM
        title m
    JOIN
        movie_keyword mk ON m.id = mk.movie_id
    JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        m.id, m.title, m.production_year
),
movies_cast AS (
    SELECT
        c.movie_id,
        COUNT(c.person_id) AS total_cast,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names
    FROM
        complete_cast cc
    JOIN
        cast_info c ON cc.movie_id = c.movie_id
    JOIN
        aka_name a ON c.person_id = a.person_id
    GROUP BY
        c.movie_id
),
movies_info AS (
    SELECT
        m.movie_id,
        STRING_AGG(DISTINCT mi.info, '; ') AS info_details
    FROM
        movie_info mi
    JOIN
        movie_info_idx m ON mi.id = m.info_type_id
    GROUP BY
        m.movie_id
)
SELECT
    mv.movie_id,
    mv.title,
    mv.production_year,
    mv.keywords,
    mc.total_cast,
    mc.cast_names,
    mi.info_details
FROM
    movie_with_keywords mv
LEFT JOIN
    movies_cast mc ON mv.movie_id = mc.movie_id
LEFT JOIN
    movies_info mi ON mv.movie_id = mi.movie_id
WHERE
    mv.production_year >= 2000
ORDER BY
    mv.production_year DESC, mv.title;
