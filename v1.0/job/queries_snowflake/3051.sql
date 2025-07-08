
WITH ranked_movies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM
        aka_title t
    LEFT JOIN
        cast_info c ON t.id = c.movie_id
    WHERE
        t.production_year IS NOT NULL
    GROUP BY
        t.id, t.title, t.production_year
),
movie_keywords AS (
    SELECT
        mk.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM
        movie_keyword mk
    JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        mk.movie_id
),
high_cast_movies AS (
    SELECT
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.total_cast,
        COALESCE(mk.keywords, 'No keywords') AS keywords
    FROM
        ranked_movies rm
    LEFT JOIN
        movie_keywords mk ON rm.movie_id = mk.movie_id
    WHERE
        rm.rank <= 5
)
SELECT
    hcm.movie_id,
    hcm.title,
    hcm.production_year,
    hcm.total_cast,
    hcm.keywords,
    ARRAY_AGG(DISTINCT p.info) AS person_details
FROM
    high_cast_movies hcm
LEFT JOIN
    complete_cast cc ON hcm.movie_id = cc.movie_id
LEFT JOIN
    person_info p ON cc.subject_id = p.person_id
GROUP BY
    hcm.movie_id, hcm.title, hcm.production_year, hcm.total_cast, hcm.keywords
ORDER BY
    hcm.production_year DESC, hcm.total_cast DESC;
