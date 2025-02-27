WITH ranked_movies AS (
    SELECT
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names,
        COUNT(DISTINCT kc.keyword) AS keyword_count
    FROM
        title t
    JOIN
        movie_companies mc ON t.id = mc.movie_id
        JOIN company_name cn ON mc.company_id = cn.id
    JOIN
        cast_info ci ON t.id = ci.movie_id
        JOIN aka_name a ON ci.person_id = a.person_id
    LEFT JOIN
        movie_keyword mk ON t.id = mk.movie_id
        JOIN keyword kc ON mk.keyword_id = kc.id
    WHERE
        t.production_year BETWEEN 2000 AND 2020
        AND cn.country_code = 'USA'
    GROUP BY
        t.id, t.title, t.production_year
),
ranked_movies_with_ratings AS (
    SELECT
        rm.movie_id,
        rm.movie_title,
        rm.production_year,
        rm.cast_names,
        rm.keyword_count,
        COALESCE(mr.rating, 0) AS user_rating
    FROM
        ranked_movies rm
    LEFT JOIN (
        SELECT movie_id, AVG(rating) AS rating
        FROM movie_info
        WHERE info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
        GROUP BY movie_id
    ) mr ON rm.movie_id = mr.movie_id
)
SELECT
    r.movie_id,
    r.movie_title,
    r.production_year,
    r.cast_names,
    r.keyword_count,
    r.user_rating,
    CASE
        WHEN r.user_rating >= 8 THEN 'Highly Rated'
        WHEN r.user_rating >= 5 THEN 'Moderately Rated'
        ELSE 'Low Rated'
    END AS rating_category
FROM
    ranked_movies_with_ratings r
ORDER BY
    r.user_rating DESC,
    r.production_year DESC;
