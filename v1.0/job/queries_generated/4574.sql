WITH RankedMovies AS (
    SELECT
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY b.name) AS rn,
        COUNT(*) OVER (PARTITION BY a.production_year) AS total_cast
    FROM
        aka_title a
    JOIN
        movie_companies mc ON a.id = mc.movie_id
    JOIN
        company_name c ON mc.company_id = c.id
    LEFT JOIN
        complete_cast cc ON a.id = cc.movie_id
    LEFT JOIN
        cast_info ci ON cc.subject_id = ci.person_id
    LEFT JOIN
        aka_name b ON ci.person_id = b.person_id
    WHERE
        a.production_year IS NOT NULL
        AND c.country_code = 'USA'
),
FilteredMovies AS (
    SELECT
        title,
        production_year,
        total_cast,
        CASE 
            WHEN total_cast > 5 THEN 'Large Cast'
            WHEN total_cast BETWEEN 3 AND 5 THEN 'Medium Cast'
            ELSE 'Small Cast'
        END AS cast_size
    FROM
        RankedMovies
    WHERE
        rn <= 10
)
SELECT
    f.title,
    f.production_year,
    f.total_cast,
    f.cast_size,
    (SELECT COUNT(*) FROM movie_keyword mk WHERE mk.movie_id IN (SELECT id FROM aka_title WHERE production_year = f.production_year)) AS keyword_count,
    (SELECT STRING_AGG(DISTINCT k.keyword, ', ') 
     FROM movie_keyword mk 
     JOIN keyword k ON mk.keyword_id = k.id 
     WHERE mk.movie_id IN (SELECT id FROM aka_title WHERE production_year = f.production_year)
    ) AS keywords
FROM
    FilteredMovies f
ORDER BY
    f.production_year DESC, f.title;
