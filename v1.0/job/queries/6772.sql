
WITH ranked_movies AS (
    SELECT
        at.id AS movie_id,
        at.title,
        at.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        ARRAY_AGG(DISTINCT ak.name) AS aka_names
    FROM
        aka_title at
    JOIN
        complete_cast cc ON at.id = cc.movie_id
    JOIN
        cast_info ci ON cc.subject_id = ci.id
    JOIN
        aka_name ak ON ci.person_id = ak.person_id
    WHERE
        at.kind_id IN (
            SELECT id FROM kind_type WHERE kind LIKE 'movie'
        )
        AND at.production_year >= 2000
    GROUP BY
        at.id, at.title, at.production_year
),
movie_keywords AS (
    SELECT
        mk.movie_id,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords
    FROM
        movie_keyword mk
    JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        mk.movie_id
)
SELECT
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.cast_count,
    rm.aka_names,
    COALESCE(mk.keywords, ARRAY[]::text[]) AS keywords
FROM
    ranked_movies rm
LEFT JOIN
    movie_keywords mk ON rm.movie_id = mk.movie_id
ORDER BY
    rm.cast_count DESC,
    rm.production_year ASC
LIMIT 50;
