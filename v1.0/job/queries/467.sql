
WITH RankedMovies AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM
        aka_title m
    JOIN
        complete_cast cc ON m.id = cc.movie_id
    LEFT JOIN
        cast_info c ON cc.subject_id = c.person_id
    WHERE
        m.production_year IS NOT NULL
    GROUP BY
        m.id, m.title, m.production_year
),
PersonDetails AS (
    SELECT
        p.id AS person_id,
        p.name,
        p.gender,
        COALESCE(pi.info, 'No Info') AS additional_info
    FROM
        name p
    LEFT JOIN
        person_info pi ON p.id = pi.person_id
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
)
SELECT
    tm.title AS movie_title,
    tm.production_year,
    COUNT(DISTINCT c.person_id) AS total_cast,
    STRING_AGG(DISTINCT pd.name, ', ') AS cast_names,
    SUM(CASE WHEN pd.gender = 'F' THEN 1 ELSE 0 END) AS female_cast_count,
    SUM(CASE WHEN pd.gender IS NULL THEN 1 ELSE 0 END) AS unknown_gender_count
FROM
    TopMovies tm
JOIN
    complete_cast cc ON tm.movie_id = cc.movie_id
JOIN
    cast_info c ON cc.subject_id = c.person_id
JOIN
    PersonDetails pd ON c.person_id = pd.person_id
GROUP BY
    tm.movie_id, tm.title, tm.production_year
ORDER BY
    tm.production_year DESC, total_cast DESC;
