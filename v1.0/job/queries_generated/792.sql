WITH movie_summary AS (
    SELECT
        mt.title AS movie_title,
        mt.production_year,
        COUNT(DISTINCT cc.subject_id) AS actor_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS actors,
        COALESCE(MIN(mci.note), 'No Note') AS company_note
    FROM
        aka_title mt
    LEFT JOIN
        complete_cast cc ON mt.id = cc.movie_id
    LEFT JOIN
        cast_info ci ON cc.subject_id = ci.person_id
    LEFT JOIN
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN
        movie_companies mci ON mt.id = mci.movie_id
    GROUP BY
        mt.id, mt.title, mt.production_year
),
keyword_summary AS (
    SELECT
        mt.id AS movie_id,
        STRING_AGG(mk.keyword, ', ') AS keywords
    FROM
        aka_title mt
    LEFT JOIN
        movie_keyword mk ON mt.id = mk.movie_id
    GROUP BY
        mt.id
)
SELECT
    ms.movie_title,
    ms.production_year,
    ms.actor_count,
    ms.actors,
    ks.keywords,
    ms.company_note
FROM
    movie_summary ms
LEFT JOIN
    keyword_summary ks ON ms.movie_title = ks.movie_id
WHERE
    ms.actor_count > 5
    AND ms.production_year >= 2000
ORDER BY
    ms.production_year DESC,
    ms.actor_count DESC
LIMIT 10;
