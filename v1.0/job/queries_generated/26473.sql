WITH RankedMovies AS (
    SELECT
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        STRING_AGG(DISTINCT an.name, ', ') AS actor_names,
        MAX(mk.keyword) AS primary_keyword
    FROM
        aka_title mt
    LEFT JOIN
        cast_info ci ON mt.id = ci.movie_id
    LEFT JOIN
        aka_name an ON ci.person_id = an.person_id
    LEFT JOIN
        movie_keyword mk ON mt.id = mk.movie_id
    WHERE
        mt.production_year > 2000
    GROUP BY
        mt.id
),
MovieDetails AS (
    SELECT
        rm.movie_id,
        rm.movie_title,
        rm.production_year,
        rm.total_cast,
        rm.actor_names,
        rnk.ranking,
        COALESCE(m_info.info, 'No Info') AS additional_info
    FROM
        RankedMovies rm
    LEFT JOIN (
        SELECT
            movie_id,
            ROW_NUMBER() OVER (ORDER BY total_cast DESC) AS ranking
        FROM
            RankedMovies
    ) rnk ON rm.movie_id = rnk.movie_id
    LEFT JOIN
        movie_info m_info ON rm.movie_id = m_info.movie_id
)
SELECT
    md.movie_title,
    md.production_year,
    md.total_cast,
    md.actor_names,
    md.ranking,
    md.additional_info
FROM
    MovieDetails md
WHERE
    md.ranking <= 10
ORDER BY
    md.total_cast DESC;
