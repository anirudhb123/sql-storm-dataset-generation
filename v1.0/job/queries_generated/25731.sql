WITH NameKeywords AS (
    SELECT
        ak.name AS actor_name,
        mt.title AS movie_title,
        mt.production_year,
        mw.keyword AS associated_keyword
    FROM
        aka_name ak
    JOIN
        cast_info ci ON ak.person_id = ci.person_id
    JOIN
        aka_title mt ON ci.movie_id = mt.movie_id
    JOIN
        movie_keyword mw ON mt.movie_id = mw.movie_id
    WHERE
        ak.name IS NOT NULL
        AND mt.production_year >= 2000
),

ActorCounts AS (
    SELECT
        actor_name,
        COUNT(DISTINCT movie_title) AS movie_count,
        STRING_AGG(DISTINCT associated_keyword, ', ') AS keywords
    FROM
        NameKeywords
    GROUP BY
        actor_name
),

TopActors AS (
    SELECT
        actor_name,
        movie_count,
        keywords
    FROM
        ActorCounts
    WHERE
        movie_count > 5
    ORDER BY
        movie_count DESC
    LIMIT 10
)

SELECT
    ta.actor_name,
    ta.movie_count,
    ta.keywords,
    ci.note AS cast_note,
    mt.kind_id AS movie_kind_id,
    ct.kind AS company_type
FROM
    TopActors ta
LEFT JOIN
    cast_info ci ON ta.actor_name = (
        SELECT ak.name FROM aka_name ak WHERE ak.person_id = ci.person_id LIMIT 1
    )
LEFT JOIN
    movie_companies mc ON ci.movie_id = mc.movie_id
LEFT JOIN
    company_type ct ON mc.company_type_id = ct.id
JOIN
    aka_title mt ON mc.movie_id = mt.movie_id
WHERE
    ct.kind IS NOT NULL
ORDER BY
    ta.movie_count DESC;
