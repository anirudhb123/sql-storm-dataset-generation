WITH ranked_movies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title ASC) AS title_rank
    FROM
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
cast_summary AS (
    SELECT
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS total_cast,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names
    FROM
        cast_info c
    JOIN
        aka_name a ON c.person_id = a.person_id
    GROUP BY
        c.movie_id
),
movie_info_summary AS (
    SELECT
        m.movie_id,
        STRING_AGG(i.info, '; ') AS info_details
    FROM
        movie_info m
    JOIN
        info_type it ON m.info_type_id = it.id
    WHERE
        it.info = 'summary'
    GROUP BY
        m.movie_id
)
SELECT
    r.movie_id,
    r.title,
    r.production_year,
    COALESCE(cs.total_cast, 0) AS total_cast,
    COALESCE(cs.cast_names, 'No Cast Found') AS cast_names,
    COALESCE(mis.info_details, 'No Info Available') AS movie_summary,
    (SELECT COUNT(*) FROM movie_keyword mk WHERE mk.movie_id = r.movie_id) AS keyword_count
FROM
    ranked_movies r
LEFT JOIN
    cast_summary cs ON r.movie_id = cs.movie_id
LEFT JOIN
    movie_info_summary mis ON r.movie_id = mis.movie_id
WHERE
    r.title_rank <= 5
ORDER BY
    r.production_year DESC, r.title;
