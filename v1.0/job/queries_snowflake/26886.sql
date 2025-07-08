
WITH RankedMovies AS (
    SELECT
        at.id AS title_id,
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.production_year DESC) AS rank_per_year
    FROM
        aka_title at
    WHERE
        at.production_year IS NOT NULL
),
TopMovies AS (
    SELECT
        title_id,
        title,
        production_year
    FROM
        RankedMovies
    WHERE
        rank_per_year <= 5
),
MovieDetails AS (
    SELECT
        tm.title_id,
        tm.title,
        tm.production_year,
        LISTAGG(DISTINCT ak.name, ', ') WITHIN GROUP (ORDER BY ak.name) AS aka_names,
        LISTAGG(DISTINCT co.name, ', ') WITHIN GROUP (ORDER BY co.name) AS company_names,
        COUNT(DISTINCT kc.keyword) AS keyword_count
    FROM
        TopMovies tm
    LEFT JOIN
        movie_companies mc ON tm.title_id = mc.movie_id
    LEFT JOIN
        company_name co ON mc.company_id = co.id
    LEFT JOIN
        movie_keyword mk ON tm.title_id = mk.movie_id
    LEFT JOIN
        keyword kc ON mk.keyword_id = kc.id
    LEFT JOIN
        complete_cast cc ON tm.title_id = cc.movie_id
    LEFT JOIN
        aka_name ak ON cc.subject_id = ak.person_id
    GROUP BY
        tm.title_id, tm.title, tm.production_year
)
SELECT
    md.title,
    md.production_year,
    md.aka_names,
    md.company_names,
    md.keyword_count
FROM
    MovieDetails md
ORDER BY
    md.production_year DESC, md.title;
