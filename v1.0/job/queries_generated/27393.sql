WITH grouped_movies AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COUNT(DISTINCT cc.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS cast_names,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords
    FROM
        aka_title mt
    JOIN
        complete_cast cc ON mt.id = cc.movie_id
    JOIN
        cast_info ci ON cc.subject_id = ci.person_id
    JOIN
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN
        movie_keyword mk ON mt.id = mk.movie_id
    LEFT JOIN
        keyword kw ON mk.keyword_id = kw.id
    WHERE
        mt.production_year BETWEEN 2000 AND 2023
    GROUP BY
        mt.id, mt.title, mt.production_year
),
ranked_movies AS (
    SELECT
        *,
        RANK() OVER (ORDER BY cast_count DESC) AS rank
    FROM
        grouped_movies
)
SELECT
    r.movie_id,
    r.title,
    r.production_year,
    r.cast_count,
    r.cast_names,
    r.keywords
FROM
    ranked_movies r
WHERE
    r.rank <= 10
ORDER BY
    r.rank;
