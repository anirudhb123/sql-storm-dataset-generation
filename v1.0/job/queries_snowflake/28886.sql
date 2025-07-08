
WITH ranked_movies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        LISTAGG(DISTINCT a.name, ', ') WITHIN GROUP (ORDER BY a.name) AS actors,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS movie_rank
    FROM
        aka_title t
    JOIN
        cast_info ci ON t.id = ci.movie_id
    JOIN
        aka_name a ON ci.person_id = a.person_id
    LEFT JOIN
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        t.id, t.title, t.production_year
),
top_movies AS (
    SELECT
        movie_id,
        title,
        production_year,
        cast_count,
        actors
    FROM
        ranked_movies
    WHERE
        movie_rank <= 5
)
SELECT
    tm.movie_id,
    tm.title,
    tm.production_year,
    tm.cast_count,
    tm.actors,
    COALESCE(mi.info, 'No additional info') AS movie_info,
    COALESCE(ct.kind, 'Unknown type') AS company_type
FROM
    top_movies tm
LEFT JOIN
    movie_info mi ON tm.movie_id = mi.movie_id
LEFT JOIN
    movie_companies mc ON tm.movie_id = mc.movie_id
LEFT JOIN
    company_type ct ON mc.company_type_id = ct.id
ORDER BY
    tm.production_year DESC, tm.cast_count DESC;
