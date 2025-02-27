
WITH RankedMovies AS (
    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rn
    FROM
        title t
    WHERE
        t.production_year IS NOT NULL
),
TopMovies AS (
    SELECT
        r.title_id,
        r.title,
        r.production_year
    FROM
        RankedMovies r
    WHERE
        r.rn <= 5
),
MovieDetails AS (
    SELECT
        tm.title_id,
        tm.title,
        tm.production_year,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names,
        COUNT(DISTINCT mc.company_id) AS production_companies,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords
    FROM
        TopMovies tm
    LEFT JOIN
        aka_title at ON tm.title_id = at.movie_id
    LEFT JOIN
        aka_name ak ON at.id = ak.id
    LEFT JOIN
        movie_companies mc ON tm.title_id = mc.movie_id
    LEFT JOIN
        movie_keyword mk ON tm.title_id = mk.movie_id
    LEFT JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        tm.title_id, tm.title, tm.production_year
)
SELECT
    md.title,
    md.production_year,
    COALESCE(md.aka_names, 'No Alternate Names') AS aka_names,
    md.production_companies,
    COALESCE(md.keywords, ARRAY['No Keywords']) AS keywords
FROM
    MovieDetails md
ORDER BY
    md.production_year DESC, md.title;
