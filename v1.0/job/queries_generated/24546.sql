WITH RankedMovies AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM
        aka_title m
    LEFT JOIN
        cast_info ci ON m.movie_id = ci.movie_id
    GROUP BY
        m.id, m.title, m.production_year
),
FilteredMovies AS (
    SELECT
        rm.movie_id,
        rm.title,
        rm.production_year,
        COALESCE(NULLIF(rm.production_year, 0), 9999) AS adjusted_year
    FROM
        RankedMovies rm
    WHERE
        rank <= 5 
    AND
        rm.production_year IS NOT NULL
),
MovieGenres AS (
    SELECT
        mt.movie_id,
        STRING_AGG(kt.keyword, ', ') AS genres
    FROM
        movie_keyword mt
    JOIN
        keyword kt ON mt.keyword_id = kt.id
    GROUP BY
        mt.movie_id
),
MovieCast AS (
    SELECT 
        ci.movie_id,
        STRING_AGG(DISTINCT ak.name, ', ') AS cast
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE
        ak.name IS NOT NULL
    GROUP BY
        ci.movie_id
)
SELECT 
    fm.movie_id,
    fm.title,
    fm.production_year,
    fm.adjusted_year,
    COALESCE(mg.genres, 'Unspecified') AS genres,
    COALESCE(mc.cast, 'No Cast Information') AS cast,
    CASE 
        WHEN fm.production_year IS NULL THEN 'Year Unknown'
        WHEN fm.production_year < 2000 THEN 'Prior to 2000'
        ELSE 'Post 2000'
    END AS year_category
FROM 
    FilteredMovies fm
LEFT JOIN 
    MovieGenres mg ON fm.movie_id = mg.movie_id
LEFT JOIN 
    MovieCast mc ON fm.movie_id = mc.movie_id
WHERE
    fm.production_year BETWEEN 1990 AND 2020
ORDER BY
    fm.adjusted_year DESC, fm.title;

This SQL query showcases advanced SQL constructs including Common Table Expressions (CTEs), string aggregation, window functions, outer joins, and complex predicate logic. Each CTE serves a specific function to refine the dataset before the final selection and uses conditions that handle NULL values and specifics about movie years, ensuring a comprehensive performance benchmarking scenario.
