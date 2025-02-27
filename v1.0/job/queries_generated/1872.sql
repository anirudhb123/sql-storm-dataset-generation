WITH RankedMovies AS (
    SELECT
        a.title,
        a.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rn
    FROM
        aka_title a
    JOIN
        cast_info ci ON a.id = ci.movie_id
    GROUP BY
        a.title,
        a.production_year
),
MovieKeywords AS (
    SELECT
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM
        movie_keyword mk
    JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        mk.movie_id
)
SELECT
    rm.title,
    rm.production_year,
    COALESCE(mk.keywords, 'No keywords') AS keywords,
    rm.cast_count,
    (SELECT AVG(CAST(m.production_year AS FLOAT))
     FROM aka_title m
     WHERE m.production_year IS NOT NULL) AS avg_production_year,
    CASE 
        WHEN rm.production_year < 2000 THEN 'Classic'
        WHEN rm.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
        ELSE 'Recent'
    END AS era
FROM
    RankedMovies rm
LEFT JOIN
    MovieKeywords mk ON rm.title = (SELECT title FROM aka_title WHERE id = mk.movie_id)
WHERE
    rm.cast_count > 5
ORDER BY
    rm.production_year DESC,
    rm.cast_count DESC;
