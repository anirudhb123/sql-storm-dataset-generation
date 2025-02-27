WITH movie_ratings AS (
    SELECT
        m.id AS movie_id,
        AVG(CASE WHEN r.rating IS NOT NULL THEN r.rating ELSE 0 END) AS avg_rating
    FROM
        title m
    LEFT JOIN 
        movie_info r ON m.id = r.movie_id AND r.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
    GROUP BY
        m.id
),
cast_details AS (
    SELECT
        ci.movie_id,
        GROUP_CONCAT(a.name ORDER BY ci.nr_order) AS cast_names,
        COUNT(ci.person_id) AS cast_count
    FROM
        cast_info ci
    JOIN
        aka_name a ON ci.person_id = a.person_id
    GROUP BY
        ci.movie_id
),
keyword_count AS (
    SELECT
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM
        movie_keyword mk
    GROUP BY
        mk.movie_id
)
SELECT
    t.title,
    t.production_year,
    COALESCE(mr.avg_rating, 0) AS average_rating,
    COALESCE(cd.cast_names, 'No Cast') AS cast_names,
    COALESCE(kc.keyword_count, 0) AS keyword_count
FROM
    title t
LEFT JOIN
    movie_ratings mr ON t.id = mr.movie_id
LEFT JOIN
    cast_details cd ON t.id = cd.movie_id
LEFT JOIN
    keyword_count kc ON t.id = kc.movie_id
WHERE
    t.production_year > 2000
    AND (kc.keyword_count > 5 OR cd.cast_count > 2)
ORDER BY
    t.production_year DESC,
    average_rating DESC
LIMIT 50;
