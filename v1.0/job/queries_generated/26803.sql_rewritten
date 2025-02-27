WITH
    MovieTitles AS (
        SELECT
            mt.id AS movie_id,
            mt.title,
            mt.production_year,
            COUNT(DISTINCT mc.company_id) AS num_companies,
            STRING_AGG(DISTINCT cn.name, ', ') AS company_names
        FROM
            aka_title mt
        LEFT JOIN
            movie_companies mc ON mt.id = mc.movie_id
        LEFT JOIN
            company_name cn ON mc.company_id = cn.id
        GROUP BY
            mt.id, mt.title, mt.production_year
    ),
    ActorNames AS (
        SELECT
            ai.movie_id,
            STRING_AGG(DISTINCT an.name, ', ') AS actor_names,
            COUNT(DISTINCT ai.person_id) AS num_actors
        FROM
            cast_info ai
        JOIN
            aka_name an ON ai.person_id = an.person_id
        GROUP BY
            ai.movie_id
    ),
    MovieKeywords AS (
        SELECT
            mk.movie_id,
            STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
        FROM
            movie_keyword mk
        JOIN
            keyword k ON mk.keyword_id = k.id
        GROUP BY
            mk.movie_id
    )
SELECT
    mt.movie_id,
    mt.title,
    mt.production_year,
    mt.num_companies,
    mt.company_names,
    an.actor_names,
    an.num_actors,
    mk.keywords
FROM
    MovieTitles mt
LEFT JOIN
    ActorNames an ON mt.movie_id = an.movie_id
LEFT JOIN
    MovieKeywords mk ON mt.movie_id = mk.movie_id
WHERE
    mt.production_year >= 2000
ORDER BY
    mt.production_year DESC, mt.title;