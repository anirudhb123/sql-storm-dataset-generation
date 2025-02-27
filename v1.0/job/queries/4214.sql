
WITH RankedMovies AS (
    SELECT
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        AVG(CAST(pi.info AS NUMERIC)) AS avg_rating,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM
        title t
    LEFT JOIN
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN
        cast_info c ON cc.subject_id = c.id
    LEFT JOIN
        movie_info mi ON t.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
    LEFT JOIN
        person_info pi ON c.person_id = pi.person_id
    GROUP BY
        t.title,
        t.production_year
)

SELECT
    rm.title,
    rm.production_year,
    rm.cast_count,
    COALESCE(rm.avg_rating, 0) AS avg_rating,
    CASE 
        WHEN rm.cast_count > 10 THEN 'Large Cast'
        WHEN rm.cast_count BETWEEN 5 AND 10 THEN 'Medium Cast'
        ELSE 'Small Cast'
    END AS cast_size_category
FROM
    RankedMovies rm
WHERE
    rm.rank <= 5
ORDER BY
    rm.production_year DESC, rm.cast_count DESC;
