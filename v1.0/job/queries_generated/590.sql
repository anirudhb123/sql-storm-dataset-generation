WITH RankedMovies AS (
    SELECT
        a.id AS movie_id,
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) AS rank_by_year
    FROM
        aka_title a
    WHERE
        a.production_year IS NOT NULL
),
MovieDetails AS (
    SELECT
        r.movie_id,
        r.title,
        r.production_year,
        ARRAY_AGG(DISTINCT cn.name) AS company_names,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM
        RankedMovies r
    LEFT JOIN
        movie_companies mc ON r.movie_id = mc.movie_id
    LEFT JOIN
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN
        complete_cast cc ON r.movie_id = cc.movie_id
    LEFT JOIN
        cast_info ci ON cc.subject_id = ci.person_id
    GROUP BY
        r.movie_id, r.title, r.production_year
),
TopMovies AS (
    SELECT
        md.*,
        RANK() OVER (ORDER BY md.production_year DESC, md.cast_count DESC) AS ranking
    FROM
        MovieDetails md
)
SELECT
    t.title,
    t.production_year,
    COALESCE(t.cast_count, 0) AS cast_count,
    COALESCE(array_to_string(t.company_names, ', '), 'No Companies') AS companies
FROM
    TopMovies t
WHERE
    t.ranking <= 10
ORDER BY
    t.production_year DESC, 
    t.cast_count DESC;
