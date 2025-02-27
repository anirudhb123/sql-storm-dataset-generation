WITH ranked_movies AS (
    SELECT
        a.title,
        a.production_year,
        COUNT(ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank_by_cast
    FROM
        aka_title a
    LEFT JOIN
        cast_info ci ON a.id = ci.movie_id
    GROUP BY
        a.id, a.title, a.production_year
),
top_movies AS (
    SELECT
        title,
        production_year,
        cast_count
    FROM
        ranked_movies
    WHERE
        rank_by_cast <= 5
),
movie_keywords AS (
    SELECT
        m.id AS movie_id,
        k.keyword
    FROM
        top_movies m
    JOIN
        movie_keyword mk ON m.movie_id = mk.movie_id
    JOIN
        keyword k ON mk.keyword_id = k.id
)
SELECT
    tm.title,
    tm.production_year,
    COALESCE(mk.keyword, 'No Keyword') AS keyword,
    (SELECT COUNT(DISTINCT c.person_id)
     FROM complete_cast c
     WHERE c.movie_id = tm.movie_id) AS distinct_cast_count,
    (SELECT
         STRING_AGG(DISTINCT p.info, ', ')
     FROM
         person_info p
     WHERE
         p.person_id IN (SELECT person_id FROM cast_info WHERE movie_id = tm.movie_id)
         AND p.info IS NOT NULL) AS cast_info
FROM
    top_movies tm
LEFT JOIN
    movie_keywords mk ON tm.movie_id = mk.movie_id
ORDER BY
    tm.production_year DESC, 
    tm.cast_count DESC;
