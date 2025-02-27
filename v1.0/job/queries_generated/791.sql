WITH MovieDetails AS (
    SELECT
        at.title AS movie_title,
        at.production_year,
        cm.name AS company_name,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS noted_cast_count,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank_within_year
    FROM
        aka_title at
    LEFT JOIN movie_companies mc ON at.id = mc.movie_id
    LEFT JOIN company_name cm ON mc.company_id = cm.id
    LEFT JOIN complete_cast cc ON at.id = cc.movie_id
    LEFT JOIN cast_info ci ON cc.subject_id = ci.person_id
    WHERE
        at.production_year BETWEEN 2000 AND 2020
    GROUP BY
        at.title, at.production_year, cm.name
),
TopMovies AS (
    SELECT
        movie_title,
        production_year,
        company_name,
        cast_count,
        noted_cast_count
    FROM
        MovieDetails
    WHERE
        rank_within_year <= 5
)
SELECT
    tm.movie_title,
    tm.production_year,
    tm.company_name,
    tm.cast_count,
    tm.noted_cast_count,
    CASE 
        WHEN tm.noted_cast_count = 0 THEN 'No notes'
        WHEN tm.noted_cast_count IS NULL THEN 'Unknown'
        ELSE 'Notes available'
    END AS notes_status
FROM
    TopMovies tm
JOIN
    (SELECT
        production_year,
        AVG(cast_count) AS avg_cast_count
     FROM
        TopMovies
     GROUP BY
        production_year) avg_cast ON tm.production_year = avg_cast.production_year
WHERE
    tm.cast_count > avg_cast.avg_cast_count
ORDER BY
    tm.production_year DESC, tm.cast_count DESC;
