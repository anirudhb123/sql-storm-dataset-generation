WITH RankedMovies AS (
    SELECT
        at.title,
        at.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM
        aka_title at
    LEFT JOIN
        cast_info ci ON at.id = ci.movie_id
    GROUP BY
        at.id, at.title, at.production_year
),
MovieKeywords AS (
    SELECT
        at.id AS movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords_list
    FROM
        aka_title at
    LEFT JOIN
        movie_keyword mk ON at.id = mk.movie_id
    LEFT JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        at.id
)
SELECT
    rm.title,
    rm.production_year,
    COALESCE(mk.keywords_list, 'No Keywords') AS keywords,
    rm.cast_count,
    CASE WHEN rm.cast_count > 5 THEN 'Large Cast'
         WHEN rm.cast_count BETWEEN 3 AND 5 THEN 'Average Cast'
         ELSE 'Small Cast' END AS cast_size
FROM
    RankedMovies rm
LEFT JOIN
    MovieKeywords mk ON rm.movie_id = mk.movie_id
WHERE
    rm.rank <= 10
ORDER BY
    rm.production_year DESC,
    rm.cast_count DESC;

SELECT DISTINCT
    c.name AS cast_member,
    m.title AS movie_title
FROM
    cast_info ci
JOIN
    aka_name c ON ci.person_id = c.person_id
JOIN
    aka_title m ON ci.movie_id = m.id
WHERE
    m.production_year IS NOT NULL AND
    c.name IS NOT NULL
EXCEPT
SELECT DISTINCT
    c.name AS cast_member,
    m.title AS movie_title
FROM
    cast_info ci
JOIN
    aka_name c ON ci.person_id = c.person_id
JOIN
    aka_title m ON ci.movie_id = m.id
WHERE
    m.production_year IS NULL OR
    c.name IS NULL;
