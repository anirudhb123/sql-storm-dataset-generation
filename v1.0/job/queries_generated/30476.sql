WITH RECURSIVE RecursiveMovies AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM
        aka_title m
    WHERE
        m.production_year >= 2000

    UNION ALL

    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        r.level + 1
    FROM
        RecursiveMovies r
    JOIN
        aka_title m ON m.episode_of_id = r.movie_id
),
MovieDetails AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        ARRAY_AGG(DISTINCT c.name) AS cast_names,
        COUNT(DISTINCT kw.keyword) AS keyword_count,
        ARRAY_AGG(DISTINCT cn.name) AS company_names
    FROM
        aka_title m
    LEFT JOIN
        cast_info ci ON ci.movie_id = m.id
    LEFT JOIN
        aka_name c ON c.person_id = ci.person_id
    LEFT JOIN
        movie_keyword mw ON mw.movie_id = m.id
    LEFT JOIN
        keyword kw ON kw.id = mw.keyword_id
    LEFT JOIN
        movie_companies mc ON mc.movie_id = m.id
    LEFT JOIN
        company_name cn ON cn.id = mc.company_id
    GROUP BY
        m.id
),
RankedMovies AS (
    SELECT
        *,
        RANK() OVER (PARTITION BY production_year ORDER BY keyword_count DESC) AS rank_by_keywords
    FROM
        MovieDetails
    WHERE
        production_year IS NOT NULL
)
SELECT
    r.movie_id,
    r.title,
    r.production_year,
    r.cast_names,
    r.keyword_count,
    r.company_names,
    r.rank_by_keywords
FROM
    RankedMovies r
WHERE
    r.rank_by_keywords <= 5
ORDER BY
    r.production_year DESC, r.keyword_count DESC;
