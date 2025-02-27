WITH RankedMovies AS (
    SELECT
        t.title,
        t.production_year,
        COUNT(c.person_id) AS cast_count,
        DENSE_RANK() OVER (ORDER BY t.production_year DESC) AS year_rank
    FROM
        title t
    LEFT JOIN
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN
        cast_info c ON cc.subject_id = c.id
    GROUP BY
        t.id,
        t.title,
        t.production_year
),
DirectorMovies AS (
    SELECT
        t.title,
        p.name AS director_name,
        t.production_year
    FROM
        title t
    JOIN
        movie_companies mc ON t.id = mc.movie_id
    JOIN
        company_name cn ON mc.company_id = cn.id
    JOIN
        person_info pi ON cn.imdb_id = pi.person_id
    JOIN
        name p ON pi.person_id = p.imdb_id
    WHERE
        mc.company_type_id = (SELECT id FROM company_type WHERE kind = 'Director')
),
KeywordCount AS (
    SELECT
        t.id AS movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM
        title t
    LEFT JOIN
        movie_keyword mk ON t.id = mk.movie_id
    GROUP BY
        t.id
)
SELECT
    rm.title,
    rm.production_year,
    rm.cast_count,
    COALESCE(dm.director_name, 'Unknown') AS director_name,
    COALESCE(kc.keyword_count, 0) AS keyword_count,
    CASE
        WHEN rm.cast_count > 10 THEN 'Large Cast'
        WHEN rm.cast_count BETWEEN 5 AND 10 THEN 'Medium Cast'
        ELSE 'Small Cast'
    END AS cast_size
FROM
    RankedMovies rm
LEFT JOIN
    DirectorMovies dm ON rm.title = dm.title AND rm.production_year = dm.production_year
LEFT JOIN
    KeywordCount kc ON rm.title = (SELECT title FROM title WHERE id = kc.movie_id)
WHERE
    rm.year_rank <= 10
ORDER BY
    rm.production_year DESC,
    rm.cast_count DESC;
