WITH RankedMovies AS (
    SELECT
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.production_year DESC) AS rn
    FROM
        aka_title at
    WHERE
        at.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('movie', 'tv series'))
),
ActorMovieCount AS (
    SELECT
        ci.person_id,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM
        cast_info ci
    GROUP BY
        ci.person_id
),
MovieKeywords AS (
    SELECT
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM
        movie_keyword mk
    JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        mk.movie_id
),
MovieInfoWithNote AS (
    SELECT
        mi.movie_id,
        mi.info,
        COALESCE(mi.note, 'N/A') AS note
    FROM
        movie_info mi
    WHERE
        mi.info_type_id IN (SELECT id FROM info_type WHERE info IN ('Box Office', 'Budget'))
)
SELECT
    am.name AS actor_name,
    rm.title AS movie_title,
    rm.production_year,
    ak.keywords,
    mi.info AS movie_info,
    COALESCE(CAST(AMC.movie_count AS VARCHAR), 'No Movies') AS actor_movie_count
FROM
    aka_name am
JOIN
    cast_info ci ON am.person_id = ci.person_id
JOIN
    RankedMovies rm ON ci.movie_id = rm.id AND rm.rn <= 3
LEFT JOIN
    MovieKeywords ak ON rm.id = ak.movie_id
LEFT JOIN
    ActorMovieCount AMC ON am.person_id = AMC.person_id
LEFT JOIN
    MovieInfoWithNote mi ON rm.id = mi.movie_id
WHERE
    am.name IS NOT NULL
ORDER BY
    rm.production_year DESC, actor_name;
