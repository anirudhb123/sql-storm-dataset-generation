WITH RankedMovies AS (
    SELECT
        at.id AS movie_id,
        at.title,
        at.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS all_cast_names
    FROM
        aka_title at
    JOIN 
        complete_cast cc ON at.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY
        at.id,
        at.title,
        at.production_year
),
TopMovies AS (
    SELECT
        movie_id,
        title,
        production_year,
        cast_count,
        all_cast_names,
        ROW_NUMBER() OVER (ORDER BY cast_count DESC) AS rank
    FROM
        RankedMovies
)
SELECT
    tm.title,
    tm.production_year,
    tm.cast_count,
    tm.all_cast_names
FROM
    TopMovies tm
WHERE
    tm.rank <= 10
ORDER BY
    tm.rank;
