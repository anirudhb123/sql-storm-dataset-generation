WITH movie_aggregates AS (
    SELECT
        a.id AS movie_id,
        MAX(t.title) AS movie_title,
        MIN(CASE WHEN c.role_id IS NOT NULL THEN r.role END) AS main_role,
        COUNT(DISTINCT k.keyword) AS keyword_count,
        COUNT(DISTINCT m.company_id) AS company_count,
        COUNT(DISTINCT p.person_id) AS cast_count
    FROM
        aka_title a
    LEFT JOIN
        cast_info c ON a.movie_id = c.movie_id
    LEFT JOIN
        role_type r ON c.role_id = r.id
    LEFT JOIN
        movie_keyword mk ON a.movie_id = mk.movie_id
    LEFT JOIN
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN
        movie_companies m ON a.movie_id = m.movie_id
    LEFT JOIN
        complete_cast cc ON a.movie_id = cc.movie_id
    LEFT JOIN
        aka_name an ON c.person_id = an.person_id
    LEFT JOIN
        name n ON an.person_id = n.imdb_id
    LEFT JOIN
        title tt ON a.id = tt.id
    GROUP BY
        a.id
),
top_movies AS (
    SELECT
        ma.movie_id,
        ma.movie_title,
        ma.main_role,
        ma.keyword_count,
        ma.company_count,
        ma.cast_count,
        RANK() OVER (ORDER BY ma.keyword_count DESC, ma.cast_count DESC) AS rank
    FROM
        movie_aggregates ma
)
SELECT
    tm.movie_title,
    tm.main_role,
    tm.keyword_count,
    tm.company_count,
    tm.cast_count
FROM
    top_movies tm
WHERE
    rank <= 10
ORDER BY
    tm.keyword_count DESC,
    tm.cast_count DESC;
