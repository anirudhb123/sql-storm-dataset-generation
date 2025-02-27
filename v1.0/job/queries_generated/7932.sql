WITH RankedMovies AS (
    SELECT
        a.title,
        a.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        STRING_AGG(DISTINCT an.name, ', ') AS actor_names
    FROM
        aka_title a
    INNER JOIN 
        complete_cast cc ON a.id = cc.movie_id
    INNER JOIN 
        cast_info c ON cc.subject_id = c.id
    INNER JOIN 
        aka_name an ON c.person_id = an.person_id
    WHERE
        a.production_year >= 2000
    GROUP BY
        a.id
),
TopMovies AS (
    SELECT
        rm.title,
        rm.production_year,
        rm.cast_count,
        ROW_NUMBER() OVER (ORDER BY rm.cast_count DESC) AS rank
    FROM
        RankedMovies rm
)
SELECT
    tm.title,
    tm.production_year,
    tm.cast_count,
    tm.rank,
    COALESCE(mk.keyword, 'No Keywords') AS keywords
FROM
    TopMovies tm
LEFT JOIN 
    movie_keyword mk ON tm.title = (SELECT title FROM aka_title WHERE id IN (SELECT movie_id FROM complete_cast WHERE subject_id = tm.rank LIMIT 1))
WHERE
    tm.rank <= 10
ORDER BY
    tm.rank;
