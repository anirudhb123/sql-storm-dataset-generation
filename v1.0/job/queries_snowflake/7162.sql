
WITH RankedMovies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        LISTAGG(DISTINCT ak.name, ', ') AS aka_names,
        LISTAGG(DISTINCT k.keyword, ', ') AS keywords
    FROM
        title t
    JOIN
        aka_title at ON t.id = at.movie_id
    JOIN
        complete_cast cc ON t.id = cc.movie_id
    JOIN
        cast_info ci ON cc.subject_id = ci.id
    JOIN
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        t.id, t.title, t.production_year
),
FilteredMovies AS (
    SELECT
        movie_id,
        title,
        production_year,
        cast_count,
        aka_names,
        keywords,
        ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY cast_count DESC) AS rank
    FROM
        RankedMovies
)
SELECT
    fm.movie_id,
    fm.title,
    fm.production_year,
    fm.cast_count,
    fm.aka_names,
    fm.keywords
FROM
    FilteredMovies fm
WHERE
    fm.rank <= 5
ORDER BY
    fm.production_year DESC, fm.cast_count DESC;
