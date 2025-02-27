WITH RankedMovies AS (
    SELECT
        mt.title AS movie_title,
        mt.production_year,
        ak.name AS actor_name,
        rk.rank,
        ROW_NUMBER() OVER (PARTITION BY mt.id ORDER BY ak.name) AS actor_position
    FROM
        aka_title mt
    JOIN
        cast_info ci ON mt.id = ci.movie_id
    JOIN
        aka_name ak ON ci.person_id = ak.person_id
    JOIN
        (SELECT
            movie_id,
            COUNT(*) AS rank
        FROM
            cast_info
        GROUP BY
            movie_id) rk ON mt.id = rk.movie_id
    WHERE
        mt.production_year IS NOT NULL
    AND
        ak.name IS NOT NULL
),
ActorDetails AS (
    SELECT
        rm.movie_title,
        rm.production_year,
        rm.actor_name,
        rm.actor_position,
        pi.info AS actor_biography,
        kt.keyword AS movie_keyword
    FROM
        RankedMovies rm
    LEFT JOIN
        person_info pi ON rm.actor_name = (SELECT name FROM aka_name WHERE person_id = pi.person_id LIMIT 1)
    LEFT JOIN
        movie_keyword mk ON rm.movie_title = (SELECT title FROM aka_title WHERE id = mk.movie_id LIMIT 1)
    LEFT JOIN
        keyword kt ON mk.keyword_id = kt.id
)
SELECT
    ad.movie_title,
    ad.production_year,
    ad.actor_name,
    ad.actor_position,
    ad.actor_biography,
    STRING_AGG(ad.movie_keyword, ', ') AS keywords
FROM
    ActorDetails ad
GROUP BY
    ad.movie_title,
    ad.production_year,
    ad.actor_name,
    ad.actor_position,
    ad.actor_biography
ORDER BY
    ad.production_year DESC,
    ad.movie_title;
