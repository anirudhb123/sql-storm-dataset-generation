WITH ranked_movies AS (
    SELECT
        at.id AS movie_id,
        at.title,
        at.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        RANK() OVER (PARTITION BY at.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank_within_year
    FROM
        aka_title at
    LEFT JOIN
        cast_info ci ON at.movie_id = ci.movie_id
    WHERE
        at.production_year IS NOT NULL
    GROUP BY
        at.id, at.title, at.production_year
),
highest_cast AS (
    SELECT
        production_year,
        title,
        cast_count
    FROM
        ranked_movies
    WHERE
        rank_within_year = 1
),
genre_keywords AS (
    SELECT
        mt.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM
        movie_keyword mk
    JOIN
        keyword k ON mk.keyword_id = k.id
    JOIN
        aka_title mt ON mk.movie_id = mt.movie_id
    WHERE
        k.keyword IS NOT NULL
    GROUP BY
        mt.movie_id
),
complete_info AS (
    SELECT
        ht.production_year,
        ht.title,
        hk.keywords,
        (SELECT COUNT(*) FROM cast_info c WHERE c.movie_id = ht.movie_id) AS extras_count,
        CASE
            WHEN ht.cast_count > 10 THEN 'Large Cast'
            WHEN ht.cast_count BETWEEN 5 AND 10 THEN 'Medium Cast'
            ELSE 'Small Cast'
        END AS cast_size
    FROM
        highest_cast ht
    LEFT JOIN
        genre_keywords hk ON ht.movie_id = hk.movie_id
)
SELECT
    ci.production_year,
    ci.title,
    COALESCE(ci.keywords, 'No keywords') AS keywords,
    COALESCE(ci.extras_count, 0) AS extras_count,
    ci.cast_size,
    CASE
        WHEN ci.extras_count IS NULL THEN 'No Extra Information'
        WHEN ci.extras_count > 5 THEN 'High Extra Count'
        ELSE 'Low Extra Count'
    END AS extra_count_status
FROM
    complete_info ci
ORDER BY
    ci.production_year DESC, ci.title;
