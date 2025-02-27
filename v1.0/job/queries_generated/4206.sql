WITH RankedMovies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(cc.id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY LENGTH(t.title)) AS title_length_rank
    FROM
        aka_title t
        LEFT JOIN complete_cast c ON t.id = c.movie_id
        LEFT JOIN cast_info cc ON c.subject_id = cc.person_id
    GROUP BY
        t.id, t.title, t.production_year
),
MoviesWithKeywords AS (
    SELECT
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.cast_count,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY rm.movie_id ORDER BY k.keyword) AS keyword_rank
    FROM
        RankedMovies rm
        LEFT JOIN movie_keyword mk ON rm.movie_id = mk.movie_id
        LEFT JOIN keyword k ON mk.keyword_id = k.id
),
CompleteMovieDetails AS (
    SELECT
        mwk.movie_id,
        mwk.title,
        mwk.production_year,
        mwk.cast_count,
        STRING_AGG(mwk.keyword, ', ') AS keywords
    FROM
        MoviesWithKeywords mwk
    GROUP BY
        mwk.movie_id, mwk.title, mwk.production_year, mwk.cast_count
)
SELECT
    cmd.movie_id,
    cmd.title,
    cmd.production_year,
    cmd.cast_count,
    cmd.keywords,
    COALESCE(mi.info, 'No additional info') AS additional_info
FROM
    CompleteMovieDetails cmd
    LEFT JOIN movie_info mi ON cmd.movie_id = mi.movie_id AND mi.info_type_id = (
        SELECT
            id FROM info_type WHERE info = 'Synopsis' LIMIT 1
    )
WHERE
    cmd.cast_count >= (
        SELECT
            AVG(cast_count) FROM RankedMovies
    )
ORDER BY
    cmd.production_year DESC, cmd.cast_count DESC;
