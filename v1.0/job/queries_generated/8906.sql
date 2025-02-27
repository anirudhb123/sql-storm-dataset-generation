WITH RankedMovies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM
        title t
    JOIN
        complete_cast cc ON t.id = cc.movie_id
    JOIN
        cast_info ci ON ci.movie_id = t.id
    GROUP BY
        t.id
),
TopMovies AS (
    SELECT
        rm.movie_id,
        rm.title,
        rm.production_year
    FROM
        RankedMovies rm
    WHERE
        rm.rank <= 5
),
MovieDetails AS (
    SELECT
        tm.title,
        tm.production_year,
        GROUP_CONCAT(DISTINCT ka.name) AS alias_names,
        GROUP_CONCAT(DISTINCT cn.name) AS company_names,
        GROUP_CONCAT(DISTINCT kw.keyword) AS keywords,
        STRING_AGG(DISTINCT pi.info) AS person_info
    FROM
        TopMovies tm
    LEFT JOIN
        aka_title at ON at.movie_id = tm.movie_id
    LEFT JOIN
        aka_name ka ON ka.id = at.id
    LEFT JOIN
        movie_companies mc ON mc.movie_id = tm.movie_id
    LEFT JOIN
        company_name cn ON cn.id = mc.company_id
    LEFT JOIN
        movie_keyword mk ON mk.movie_id = tm.movie_id
    LEFT JOIN
        keyword kw ON kw.id = mk.keyword_id
    LEFT JOIN
        complete_cast cc ON cc.movie_id = tm.movie_id
    LEFT JOIN
        person_info pi ON pi.person_id = cc.person_id
    GROUP BY
        tm.title, tm.production_year
)
SELECT
    md.title,
    md.production_year,
    md.alias_names,
    md.company_names,
    md.keywords,
    md.person_info
FROM
    MovieDetails md
ORDER BY
    md.production_year DESC;
