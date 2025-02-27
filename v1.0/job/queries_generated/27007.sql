WITH RankedMovies AS (
    SELECT
        at.id AS title_id,
        at.title,
        at.production_year,
        ak.name AS actor_name,
        ci.nr_order,
        ROW_NUMBER() OVER (PARTITION BY at.id ORDER BY ci.nr_order) AS actor_rank
    FROM
        aka_title at
    JOIN
        movie_keyword mk ON at.id = mk.movie_id
    JOIN
        aka_name ak ON mk.keyword_id = (SELECT id FROM keyword WHERE keyword = 'actor')
    JOIN
        cast_info ci ON ci.movie_id = at.id AND ci.person_id = ak.person_id
    WHERE
        at.production_year >= 2000
),

MovieInfo AS (
    SELECT
        m.title_id,
        m.title,
        m.production_year,
        STRING_AGG(DISTINCT m.actor_name, ', ') AS actors
    FROM
        RankedMovies m
    GROUP BY
        m.title_id, m.title, m.production_year
),

KeywordsWithCounts AS (
    SELECT
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM
        movie_keyword mk
    GROUP BY
        mk.movie_id
)

SELECT
    mi.title,
    mi.production_year,
    mi.actors,
    kw.keyword_count
FROM
    MovieInfo mi
JOIN
    KeywordsWithCounts kw ON mi.title_id = kw.movie_id
ORDER BY
    mi.production_year DESC,
    kw.keyword_count DESC;
